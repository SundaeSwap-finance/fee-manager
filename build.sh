aiken() {
  ~/proj/aiken/target/release/aiken $*
}

set -e

echo

echo "Git commit       = $(git rev-parse HEAD)"
echo "Aiken Version    = $(aiken --version)"

echo
SHA256=$(cat validators/fee-manager.ak | sha256sum | cut -f 1 -d ' ')
echo "validators/fee-manager.ak                 = ${SHA256}"

echo


POOL_SCRIPT="D87A9F581C44A1EB2D9F58ADD4EB1932BD0048E6A1947E85E3FE4F32956A110414FF"
OWNER="D8799F581C503540B7F707CC4BF0BC4056D34126C1113BAE8C09BE082904C4AAFDFF"
MANAGER="D8799F581CB9F34F2CC7110735CE3F7E4A7FE608C4DF21A3AB061A56597D0751CDFF"
echo

aiken build -t silent &> /dev/null

aiken blueprint apply -v fee_manager.fee_manager.withdraw "${POOL_SCRIPT}" 2> /dev/null > tmp
mv tmp plutus.json
aiken blueprint apply -v fee_manager.fee_manager.withdraw "${OWNER}" 2> /dev/null > tmp
mv tmp plutus.json
aiken blueprint apply -v fee_manager.fee_manager.withdraw "${MANAGER}" 2> /dev/null > tmp
mv tmp plutus.json

SCRIPT_HASH=$(aiken blueprint policy -v fee_manager.fee_manager.withdraw 2> /dev/null)


echo "Parameters:"
echo -e " - Pool Script:     = \e[32m ${POOL_SCRIPT} \e[0m"
echo -e " - Owner:           = \e[32m ${OWNER} \e[0m"
echo -e " - Manager:         = \e[32m ${MANAGER} \e[0m"

echo -e "Script Hashes:"
echo -e " - Fee Manager      = \e[32m ${SCRIPT_HASH} \e[0m"

echo -e "Fee Manager CBOR:"
echo -e " - d87f9f581c${SCRIPT_HASH}ff"

echo
echo
