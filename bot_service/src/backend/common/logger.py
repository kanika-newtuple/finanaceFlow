import logging
import os
import shutil
from logging.handlers import TimedRotatingFileHandler
from uuid import uuid4

from opentelemetry import trace
from opentelemetry._logs import set_logger_provider
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.resources import Resource

# Get the terminal width
terminal_width = shutil.get_terminal_size().columns

# Set up the logger
logger = logging.getLogger(__name__)

log_dir = os.path.join(os.path.normpath(os.getcwd() + os.sep + os.pardir), "logs")
log_fname = os.path.join(log_dir, "logger.log")

if not os.path.exists(log_dir):
    os.mkdir(log_dir)

# Configure the RichHandler with console width
# shell_handler = RichHandler(console=Console(width=terminal_width))
shell_handler = logging.StreamHandler()
file_handler = TimedRotatingFileHandler(log_fname.strip("."), when="midnight", backupCount=30)
file_handler.suffix = r"%Y-%m-%d-%H-%M-%S.log"

logger.setLevel(logging.DEBUG)
shell_handler.setLevel(logging.DEBUG)
file_handler.setLevel(logging.DEBUG)

# Formatters for shell and file
fmt_shell = "%(message)s"
fmt_file = "%(levelname)4s %(asctime)s [%(filename)s:%(funcName)s:%(lineno)d] %(message)s"
otel_fmt_file = "%(levelname)4s %(asctime)s [%(filename)s:%(funcName)s:%(lineno)d] %(message)s [%(trace_id)s:%(span_id)s]"

# shell_formatter = logging.Formatter(fmt_shell)
shell_formatter = logging.Formatter(fmt_file)
file_formatter = logging.Formatter(fmt_file)
otel_formatter = logging.Formatter(otel_fmt_file)

# Set formatters
shell_handler.setFormatter(shell_formatter)
file_handler.setFormatter(file_formatter)

# Add handlers
logger.addHandler(shell_handler)
logger.addHandler(file_handler)


AGENT_HOSTNAME = os.getenv("AGENT_HOSTNAME", "localhost")
AGENT_PORT = int(os.getenv("AGENT_PORT", "4317"))


class SpanFormatter(logging.Formatter):
    def __init__(self, fmt=None, datefmt=None):
        super().__init__(fmt, datefmt)
        self._current_trace_id = None
        self._current_span_id = None

    def format(self, record):
        span = trace.get_current_span()
        context = span.get_span_context()
        trace_id = context.trace_id
        span_id = context.span_id

        if trace_id == 0:
            # Use existing IDs if we're in the same trace context
            if not self._current_trace_id:
                self._current_trace_id = uuid4().hex
                self._current_span_id = uuid4().hex
            record.trace_id = self._current_trace_id
            record.span_id = self._current_span_id
        else:
            # Reset stored IDs when we get a real trace context
            self._current_trace_id = "{trace:032x}".format(trace=trace_id)
            self._current_span_id = "{span:032x}".format(span=span_id)
            record.trace_id = self._current_trace_id
            record.span_id = self._current_span_id

        return super().format(record)


resource = Resource(attributes={"service.name": "service-foobar"})

# Create and set the logger provider
logger_provider = LoggerProvider(resource)
set_logger_provider(logger_provider)

# Create the OTLP log exporter that sends logs to configured destination
exporter = OTLPLogExporter()
logger_provider.add_log_record_processor(BatchLogRecordProcessor(exporter))

# Attach OTLP handler to root logger
handler = LoggingHandler(logger_provider=logger_provider)
handler.setFormatter(SpanFormatter(otel_fmt_file))

logger.addHandler(handler)
logger_provider.shutdown()
