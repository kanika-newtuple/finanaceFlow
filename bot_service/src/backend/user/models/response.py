from pydantic import BaseModel


class UserResponse(BaseModel):
    """Represents the user API Request"""

    id: int
    username: str
    email: str
    is_active: bool

    class Config:
        from_attributes = True
