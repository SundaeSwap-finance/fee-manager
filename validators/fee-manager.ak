use aiken/crypto.{VerificationKey, Signature}
use aiken/cbor
use aiken/collection/list
use aiken/interval.{intersection}
use cardano/address.{Credential, PaymentCredential}
use cardano/assets.{PolicyId, AssetName}
use cardano/transaction.{Transaction, ValidityRange, find_datum, InlineDatum, DatumHash}
use sundae/multisig

pub type NewFee {
  valid_range: ValidityRange,
  bid_fees_per_10_thousand: Int,
  ask_fees_per_10_thousand: Int,
}

pub type NewFeeManager {
  valid_range: ValidityRange,
  fee_manager: Option<multisig.MultisigScript>,
}

pub type Redeemer {
  UpdateFee { new_fee: NewFee, signatures: List<(VerificationKey, Signature)> }
  UpdateFeeManager { new_fee_manager: NewFeeManager, signatures: List<(VerificationKey, Signature)> }
}

// An abbreviated version of the Sundae v3 pool datum
pub type AssetClass = (PolicyId, AssetName)
pub type PoolDatum {
  ident: ByteArray,
  assets: (AssetClass, AssetClass),
  circulating_lp: Int,
  bid_fees_per_10_thousand: Int,
  ask_fees_per_10_thousand: Int,
  fee_manager: Option<multisig.MultisigScript>,
  market_open: Int,
  protocol_fees: Int,
}

validator fee_manager(
  pool_script_hash: PaymentCredential,
  owner: multisig.MultisigScript,
  manager: multisig.MultisigScript,
) {
  withdraw(redeemer: Redeemer, _account: Credential, self: Transaction) {
    let Transaction { validity_range, withdrawals, outputs, datums, .. } = self
    expect Some(pool_output) = list.find(outputs, fn(o) { o.address.payment_credential == pool_script_hash })
    expect Some(pool_datum) = when pool_output.datum is {
      InlineDatum(datum) -> Some(datum)
      DatumHash(hash) -> find_datum(outputs, datums, hash)
      _ -> error "Invalid pool datum"
    }
    expect PoolDatum { bid_fees_per_10_thousand, ask_fees_per_10_thousand, fee_manager, .. } = pool_datum
    when redeemer is {
      UpdateFee { new_fee, signatures } -> {
        let payload = cbor.serialise(new_fee)
        and {
          multisig.satisfied_payload(manager, payload, signatures, validity_range, withdrawals),
          intersection(validity_range, new_fee.valid_range) == validity_range,
          bid_fees_per_10_thousand == new_fee.bid_fees_per_10_thousand,
          ask_fees_per_10_thousand == new_fee.ask_fees_per_10_thousand,
        }
      }
      UpdateFeeManager { new_fee_manager, signatures } -> {
        let payload = cbor.serialise(new_fee_manager)
        and {
          multisig.satisfied_payload(owner, payload, signatures, validity_range, withdrawals),
          intersection(validity_range, new_fee_manager.valid_range) == validity_range,
          fee_manager == new_fee_manager.fee_manager,
        }
      }
    }
  }

  else(_) {
    fail
  }
}
