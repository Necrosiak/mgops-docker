# =============================================================================
# NetworkMemories — MGO1 Java Server
# Base: Eclipse Temurin JDK 8 (required by the original server code)
# =============================================================================
FROM eclipse-temurin:8-jdk AS builder

WORKDIR /build

# Copy source and libs
COPY src/ ./src/
COPY lib/ ./lib/

# Compile all Java sources
RUN find src -name "*.java" > sources.txt && \
    javac -cp "lib/*" -d out @sources.txt

# --- Runtime image ---
FROM eclipse-temurin:8-jre

WORKDIR /app

COPY --from=builder /build/out ./classes
COPY --from=builder /build/lib ./lib

# Entrypoint script that injects env vars
COPY docker/server/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6731 6732 6733 6734 6735

ENTRYPOINT ["/entrypoint.sh"]
