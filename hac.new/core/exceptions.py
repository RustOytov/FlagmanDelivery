"""Исключения приложения для единообразных ответов API."""


class AppException(Exception):
    """Базовое исключение с HTTP-статусом и текстом для клиента."""

    def __init__(self, detail: str, status_code: int = 500) -> None:
        self.detail = detail
        self.status_code = status_code
        super().__init__(detail)


class NotFoundException(AppException):
    def __init__(self, detail: str = "Ресурс не найден") -> None:
        super().__init__(detail, status_code=404)


class UnauthorizedException(AppException):
    def __init__(self, detail: str = "Требуется авторизация") -> None:
        super().__init__(detail, status_code=401)


class ForbiddenException(AppException):
    def __init__(self, detail: str = "Доступ запрещён") -> None:
        super().__init__(detail, status_code=403)


class ConflictException(AppException):
    def __init__(self, detail: str = "Конфликт данных") -> None:
        super().__init__(detail, status_code=409)


class ValidationException(AppException):
    def __init__(self, detail: str = "Ошибка валидации") -> None:
        super().__init__(detail, status_code=422)
