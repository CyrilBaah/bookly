from typing import List

from fastapi import FastAPI, status
from fastapi.exceptions import HTTPException
from pydantic import BaseModel

app = FastAPI()


books = [
    {
        "id": 1,
        "title": "1984",
        "author": "George Orwell",
        "publisher": "Secker & Warburg",
        "publisher_date": "1949-06-08",
        "page_count": 328,
        "language": "English",
    },
    {
        "id": 2,
        "title": "To Kill a Mockingbird",
        "author": "Harper Lee",
        "publisher": "J.B. Lippincott & Co.",
        "publisher_date": "1960-07-11",
        "page_count": 281,
        "language": "English",
    },
    {
        "id": 3,
        "title": "The Great Gatsby",
        "author": "F. Scott Fitzgerald",
        "publisher": "Charles Scribner's Sons",
        "publisher_date": "1925-04-10",
        "page_count": 180,
        "language": "English",
    },
]


@app.get("/books", response_model=List[dict])
def get_books():
    return books


@app.get("/books/{book_id}", response_model=dict)
def get_book(book_id: int):
    for book in books:
        if book["id"] == book_id:
            return book
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Book not found")


@app.post("/book", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_book(book: dict):
    new_id = max(book["id"] for book in books) + 1 if books else 1
    book["id"] = new_id
    books.append(book)
    return book


@app.put("/books/{book_id}", response_model=dict)
def update_book(book_id: int, book: dict):
    for index, existing_book in enumerate(books):
        if existing_book["id"] == book_id:
            books[index] = {**existing_book, **book}
            return books[index]
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Book not found")


@app.delete("/books/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_book(book_id: int):
    for index, book in enumerate(books):
        if book["id"] == book_id:
            del books[index]
            return
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Book not found")


@app.get("/health", status_code=status.HTTP_200_OK)
def health_check():
    return {"status": "ok", "message": "API is running smoothly"}
