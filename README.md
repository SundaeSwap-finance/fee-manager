# fee-manager

This is a small aiken validator meant to solve two problems:

1) Updating a pool requires spending the pool UTXO, which means in the case of a multsig fee manager, requires really tricky timing.
2) Splitting permission to update the fee manager (the "owner"), and the fees (the "manager")
