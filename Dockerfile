# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry

WORKDIR /app

# Copy the project files
COPY . .

# Ensure proper permissions for the output directory
RUN mkdir -p /app/out && chmod -R 777 /app/out

# Install forge libraries before building
RUN forge install

# Install dependencies and build
RUN forge build

# Run the script using the RPC from .env
CMD source .env && \
    forge script script/VerifySPV.s.sol:SPVDeploy --broadcast --rpc-url $RPC_URL