class DBException(Exception):
    def __init__(self, missing_fields: list):
        super().__init__(missing_fields)
