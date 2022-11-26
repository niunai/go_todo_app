# デプロイ用コンテナに含めるバイナリを作成するコンテナ
FROM golang:1.19.3-bullseye as deploy-builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -trimpath -ldflags "-w -s" -o app

# -trimpath
#         remove all file system paths from the resulting executable.
#         Instead of absolute file system paths, the recorded file names
#         will begin either a module path@version (when using modules),
#         or a plain import path (when using the standard library, or GOPATH).

# You will get the smallest binaries if you compile with -ldflags '-w -s'.
# The -w turns off DWARF debugging information: you will not be able to use gdb on the binary to look at specific functions or set breakpoints or get stack traces, because all the metadata gdb needs will not be included. You will also not be able to use other tools that depend on the information, like pprof profiling.
# The -s turns off generation of the Go symbol table: you will not be able to use go tool nm to list the symbols in the binary. strip -s is like passing -s to -ldflags but it doesn't strip quite as much. go tool nm might still work after strip -s. I am not completely sure.
#
# $ go tool link

# ---------------------------------------------------

FROM debian:bullseye-slim as deploy

RUN apt-get update

COPY --from=deploy-builder /app/app .

CMD ["./app"]

# ---------------------------------------------------

FROM golang:1.19.3 as dev
WORKDIR /app
RUN go install github.com/cosmtrek/air@latest
CMD ["air"]
