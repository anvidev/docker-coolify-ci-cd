FROM golang:1.23 AS builder
WORKDIR /app 
COPY go.* .
RUN go mod download && go mod verify
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o api ./cmd/api

FROM scratch
WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/api .
EXPOSE 8080
CMD ["./api"]
