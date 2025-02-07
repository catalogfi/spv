FROM evm-base:latest

WORKDIR /app

# Copy the project files
COPY . .

# Install dependencies and build
# RUN forge build

# Expose default Anvil port
# EXPOSE 8545

# Start Anvil and deploy contracts
# CMD source .env && anvil -m $MNEMONIC --host 0.0.0.0 & sleep 5 && \
#     forge script script/VerifySPV.s.sol:SPVDeploy 0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4adae5494dffff7f2002000000 0 2 true --sig 'run(bytes,uint256,uint256,bool)' --broadcast --rpc-url http://localhost:8545 && \
#     tail -f /dev/null

CMD while true; do sleep 1; done