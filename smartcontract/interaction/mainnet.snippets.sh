KEYSTORE_FILE="./wallets/erd1lcdv6l4gr6ex3q86gmpcxv033j0ng75ypmxkwnhjzkjk2qhhs95q4rt2se.json"
PASS_FILE="./wallets/pass.txt"

ADDRESS=$(erdpy data load --key=address-mainnet)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-mainnet)
PROXY=https://api.elrond.com
CHAIN=1


OWNER_ADRESS="erd10ypsxdd04qmcwt8f0n9kcs4fjxjvvcw7nz62t8fxzhq0rnh8wjtslpjzvq"


DEPLOY_GAS="19001610"
TARGET=1000000000000000000
MINIMUM_DEPOSIT=1000000000000000000
MAXIMUM_DEPOSIT=3000000000000000000
DEADLINE_UNIX_TIMESTAMP=$(date -d "2022-06-12 23:59:59" +%s)

deploy() {
    erdpy --verbose contract deploy --project=${PROJECT} --recall-nonce \
    --keyfile=${KEYSTORE_FILE} --passfile=${PASS_FILE} \
    --gas-limit=${DEPLOY_GAS} --metadata-payable-by-sc --metadata-payable \
    --arguments ${TARGET} ${MINIMUM_DEPOSIT} ${MAXIMUM_DEPOSIT} ${DEADLINE_UNIX_TIMESTAMP} \
    --outfile="deploy-mainnet.interaction.json" --send --proxy=${PROXY} --chain=${CHAIN} || return

    TRANSACTION=$(erdpy data parse --file="deploy-mainnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(erdpy data parse --file="deploy-mainnet.interaction.json" --expression="data['contractAddress']")

    erdpy data store --key=address-mainnet --value=${ADDRESS}
    erdpy data store --key=deployTransaction-mainnet --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

deploySimulate() {
    erdpy --verbose contract deploy --project=${PROJECT} --recall-nonce --gas-limit=${DEPLOY_GAS} \
        --keyfile=${KEYSTORE_FILE} --passfile=${PASS_FILE} --metadata-payable-by-sc --metadata-payable \
        --arguments ${TARGET} ${MINIMUM_DEPOSIT} ${MAXIMUM_DEPOSIT} ${DEADLINE_UNIX_TIMESTAMP} \
        --outfile="simulate-mainnet.interaction.json" --simulate --proxy=${PROXY} --chain=${CHAIN} || return

    TRANSACTION=$(erdpy data parse --file="simulate-mainnet.interaction.json" --expression="data['simulation']['execution']['result']['hash']")
    ADDRESS=$(erdpy data parse --file="simulate-mainnet.interaction.json" --expression="data['contractAddress']")
    RETCODE=$(erdpy data parse --file="simulate-mainnet.interaction.json" --expression="data['simulation']['execution']['result']['status']")
    RETMSG=$(erdpy data parse --file="simulate-mainnet.interaction.json" --expression="data['simulation']['execution']['result']['returnMessage']")

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
    erdpy --verbose contract call ${ADDRESS} --recall-nonce --gas-limit=10000000 \
        --keyfile=${KEYSTORE_FILE} --passfile=${PASS_FILE} \
        --function="claim" \
        --proxy=${PROXY} --chain=${CHAIN} \
        --send
}


changeOwner() {
    erdpy --verbose contract call ${ADDRESS} --recall-nonce --gas-limit=10000000 \
        --keyfile=${KEYSTORE_FILE} --passfile=${PASS_FILE} \
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
