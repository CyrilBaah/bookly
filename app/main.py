from typing import List
import time
import random

from fastapi import FastAPI, status, Request, Response
from fastapi.exceptions import HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Prometheus metrics
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# OpenTelemetry for tracing
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Set up OpenTelemetry
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Configure the OTLP exporter to send traces to Tempo
# In production, this would be configured to point to your Tempo instance
otlp_exporter = OTLPSpanExporter(endpoint="http://tempo.monitoring:4318/v1/traces")
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Create Prometheus metrics
REQUEST_COUNT = Counter(
    "bookly_request_count", "App Request Count", ["app_name", "method", "endpoint", "http_status"]
)
REQUEST_LATENCY = Histogram(
    "bookly_request_latency_seconds", "Request latency", ["app_name", "endpoint"]
)

app = FastAPI(
    title="Bookly API", description="API for managing books with observability"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Instrument FastAPI with OpenTelemetry
FastAPIInstrumentor.instrument_app(app)

# Add middleware for metrics
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    process_time = time.time() - start_time
    REQUEST_LATENCY.labels("bookly_api", request.url.path).observe(process_time)
    REQUEST_COUNT.labels("bookly_api", request.method, request.url.path, response.status_code).inc()
    
    return response

# Endpoint to expose Prometheus metrics
@app.get("/metrics")
def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

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


@app.get("/")
def root():
    return {"message": "Welcome to Bookly API", "version": "1.0.0"}


@app.get("/books", response_model=List[dict])
def get_books():
    # Add a small random delay to simulate variable response times
    time.sleep(random.uniform(0.01, 0.1))
    return books


@app.get("/books/{book_id}", response_model=dict)
def get_book(book_id: int):
    with tracer.start_as_current_span("get_book_by_id") as span:
        span.set_attribute("book.id", book_id)
        
        # Add a small random delay to simulate variable response times
        time.sleep(random.uniform(0.05, 0.2))
        
        for book in books:
            if book["id"] == book_id:
                span.set_attribute("book.title", book["title"])
                return book
                
        span.set_attribute("error", True)
        span.set_attribute("error.message", f"Book with id {book_id} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Book not found")


@app.post("/books", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_book(book: dict):
    with tracer.start_as_current_span("create_book") as span:
        # Add a small random delay to simulate variable response times
        time.sleep(random.uniform(0.1, 0.3))
        
        new_id = max(book["id"] for book in books) + 1 if books else 1
        book["id"] = new_id
        books.append(book)
        
        span.set_attribute("book.id", new_id)
        span.set_attribute("book.title", book["title"])
        return book


@app.put("/books/{book_id}", response_model=dict)
def update_book(book_id: int, book: dict):
    with tracer.start_as_current_span("update_book") as span:
        span.set_attribute("book.id", book_id)
        
        # Add a small random delay to simulate variable response times
        time.sleep(random.uniform(0.1, 0.25))
        
        for index, existing_book in enumerate(books):
            if existing_book["id"] == book_id:
                books[index] = {**existing_book, **book, "id": book_id}
                span.set_attribute("book.title", books[index]["title"])
                return books[index]
                
        span.set_attribute("error", True)
        span.set_attribute("error.message", f"Book with id {book_id} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Book not found")


@app.delete("/books/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_book(book_id: int):
    with tracer.start_as_current_span("delete_book") as span:
        span.set_attribute("book.id", book_id)
        
        # Add a small random delay to simulate variable response times
        time.sleep(random.uniform(0.05, 0.15))
        
        for index, book in enumerate(books):
            if book["id"] == book_id:
                del books[index]
                return
                
        span.set_attribute("error", True)
        span.set_attribute("error.message", f"Book with id {book_id} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Book not found")


@app.get("/health", status_code=status.HTTP_200_OK)
def health_check():
    return {"status": "ok", "message": "API is running smoothly"}


# Simulate an endpoint with errors for demonstration purposes
@app.get("/error")
def simulate_error():
    with tracer.start_as_current_span("simulate_error") as span:
        span.set_attribute("error", True)
        span.set_attribute("error.type", "SimulatedError")
        span.set_attribute("error.message", "This is a simulated error")
        
        # Randomly generate errors about 50% of the time
        if random.random() > 0.5:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                               detail="Simulated server error")
        return {"message": "No error this time!"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
