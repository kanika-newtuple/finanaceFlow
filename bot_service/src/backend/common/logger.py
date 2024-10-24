import logging
import os
from logging.handlers import TimedRotatingFileHandler
from pathlib import Path
# from pythonjsonlogger import jsonlogger

# from rich.logging import RichHandler

logger = logging.getLogger(__name__)
path = Path(__file__)

log_dir = path.parent.parent / "logs" 
log_dir.mkdir(exist_ok=True, parents=True)
log_fname = (log_dir / "logger.log").as_posix()

shell_handler = logging.StreamHandler()
# shell_handler = RichHandler(tracebacks_word_wrap=False)
# shell_handler = RichHandler()
file_handler = TimedRotatingFileHandler(log_fname.strip("."), when="midnight", backupCount=30)
file_handler.suffix = r"%Y-%m-%d.log"

logger.setLevel(logging.DEBUG)
shell_handler.setLevel(logging.DEBUG)
file_handler.setLevel(logging.DEBUG)

# the formatter determines what our logs will look like
# fmt_shell = '%(levelname)s %(asctime)s %(message)s'
fmt_shell = "%(message)s"
fmt_file = "%(levelname)s %(asctime)s [%(filename)s:%(funcName)s:%(lineno)d] %(message)s"

shell_formatter = logging.Formatter(fmt_shell)
file_formatter = logging.Formatter(fmt_file)

# here we hook everything together
# json_formatter = jsonlogger.JsonFormatter()
# shell_formatter = shell_handler.setFormatter(json_formatter)
shell_handler.setFormatter(shell_formatter)
file_handler.setFormatter(file_formatter)

logger.addHandler(shell_handler)
logger.addHandler(file_handler)