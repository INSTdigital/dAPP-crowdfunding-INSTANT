KEYSTORE_FILE="./wallets/erd1lcdv6l4gr6ex3q86gmpcxv033j0ng75ypmxkwnhjzkjk2qhhs95q4rt2se.json"
PASS_FILE="./wallets/pass.txt"
ALICE="/home/renault/elrondsdk/testwallets/latest/users/alice.pem"
BOB="/home/renault/elrondsdk/testwallets/latest/users/bob.pem"


ADDRESS=$(erdpy data load --key=address-testnet)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-testnet)
PROXY=https://testnet-api.elrond.com
CHAIN=T

OWNER_ADRESS="erd1lcdv6l4gr6ex3q86gmpcxv033j0ng75ypmxkwnhjzkjk2qhhs95q4rt2se"


DEPLOY_GAS="21723100"
TARGET=1000000000000000000
MINIMUM_DEPOSIT=2000000000000000000
MAXIMUM_DEPOSIT=100000000000000000000
DEADLINE_UNIX_TIMESTAMP=$(date -d "2022-04-20 08:00:00" +%s)

deploy() {
    erdpy --verbose contract deploy --project=${PROJECT} --recall-nonce \
    --pem=${ALICE} \
    --gas-limit=${DEPLOY_GAS} --metadata-payable-by-sc --metadata-payable \
    --arguments ${TARGET} ${MINIMUM_DEPOSIT} ${MAXIMUM_DEPOSIT} ${DEADLINE_UNIX_TIMESTAMP} \
    --outfile="deploy-testnet.interaction.json" --send --proxy=${PROXY} --chain=${CHAIN} || return

    TRANSACTION=$(erdpy data parse --file="deploy-testnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(erdpy data parse --file="deploy-testnet.interaction.json" --expression="data['contractAddress']")

    erdpy data store --key=address-testnet --value=${ADDRESS}
    erdpy data store --key=deployTransaction-testnet --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

deploySimulate() {
    erdpy --verbose contract deploy --project=${PROJECT} --recall-nonce --gas-limit=${DEPLOY_GAS} \
    --pem=${ALICE} \
    --arguments ${TARGET} ${MINIMUM_DEPOSIT} ${MAXIMUM_DEPOSIT} ${DEADLINE_UNIX_TIMESTAMP} \
    --outfile="simulate-testnet.interaction.json" --simulate --proxy=${PROXY} --chain=${CHAIN} || return

    TRANSACTION=$(erdpy data parse --file="simulate-testnet.interaction.json" --expression="data['simulation']['execution']['result']['hash']")
    ADDRESS=$(erdpy data parse --file="simulate-testnet.interaction.json" --expression="data['contractAddress']")
    RETCODE=$(erdpy data parse --file="simulate-testnet.interaction.json" --expression="data['simulation']['execution']['result']['status']")
    RETMSG=$(erdpy data parse --file="simulate-testnet.interaction.json" --expression="data['simulation']['execution']['result']['returnMessage']")

    echo ""
    echo "Simulated transaction: ${TRANSACTION}"
    echo "Smart contract address: ${ADDRESS}"
    echo "Deployment return code: ${RETCODE}"
    echo "Deployment return message: ${RETMSG}"
}


checkDeployment() {
    erdpy tx get --hash=$DEPLOY_TRANSACTION --omit-fields="['data', 'signature']" --proxy=${PROXY}
    erdpy account get --address=$ADDRESS --omit-fields="['code']" --proxy=${PROXY}
}


claimFunds() {
    erdpy --verbose contract call ${ADDRESS} --recall-nonce --pem=${ALICE} --gas-limit=10000000 \
        --function="claim" \
        --proxy=${PROXY} --chain=${CHAIN} \
        --send
}


changeOwner() {
    erdpy --verbose contract call ${ADDRESS} --recall-nonce --gas-limit=10000000 \
        --pem=${ALICE} \
        --function="ChangeOwnerAddress" --arguments ${OWNER_ADRESS} \
        --proxy=${PROXY} --chain=${CHAIN} \
        --send
}

# 0 - Funding Period
# 1 - Successful
# 2 - Failed
status() {
    erdpy --verbose contract query ${ADDRESS} --function="status" --proxy=${PROXY}
}

getCurrentFunds() {
    erdpy --verbose contract query ${ADDRESS} --function="getCurrentFunds" --proxy=${PROXY}
}

getTarget() {
    erdpy --verbose contract query ${ADDRESS} --function="getTarget" --proxy=${PROXY}
}

getDeadline() {
    erdpy --verbose contract query ${ADDRESS} --function="getDeadline" --proxy=${PROXY}
}

# BOB's deposit
getDeposit() {
    local BOB_ADDRESS_BECH32=erd1spyavw0956vq68xj8y4tenjpq2wd5a9p2c6j8gsz7ztyrnpxrruqzu66jx
    local BOB_ADDRESS_HEX=0x$(erdpy wallet bech32 --decode ${BOB_ADDRESS_BECH32})

    erdpy --verbose contract query ${ADDRESS} --function="getDeposit" --arguments ${BOB_ADDRESS_HEX} --proxy=${PROXY}
}

getCrowdfundingTokenName() {
    erdpy --verbose contract query ${ADDRESS} --function="getCrowdfundingTokenIdentifier" --proxy=${PROXY}
}
