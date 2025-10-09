import InsuranceVault from "../contracts/InsuranceVault.cdc"

access(all) fun main(): InsuranceVault.VaultData {
    return InsuranceVault.getVaultStats()
}
