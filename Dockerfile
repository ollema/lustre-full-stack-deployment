ARG GLEAM_VERSION=v1.2.1

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

# Add project code
COPY ./common /build/common
COPY ./client /build/client
COPY ./server /build/server

# NOTE: This step is normally not needed and should not be included in the guide
RUN cd /build/common \
  && gleam run -m lustre/dev build component common/counter --outdir=/build/server/priv/static

# Compile the client code
RUN cd /build/client \
  && gleam run -m lustre/dev build app --outdir=/build/server/priv/static

# Compile the server code
RUN cd /build/server \
  && gleam export erlang-shipment

# Start from a clean slate
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine

# Copy the compiled server code from the builder stage
COPY --from=builder /build/server/build/erlang-shipment /app

# Run the server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
