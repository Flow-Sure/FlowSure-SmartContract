import FungibleToken from "FungibleToken"
import FlowToken from "FlowToken"

access(all) contract InsuranceVault {
    
    access(all) event VaultDepositEvent(
        depositor: Address,
        amount: UFix64,
        newBalance: UFix64,
        timestamp: UFix64
    )
    
    access(all) event VaultPayoutEvent(
        recipient: Address,
        amount: UFix64,
        remainingBalance: UFix64,
        timestamp: UFix64
    )
    
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    
    access(all) var totalPoolBalance: UFix64
    access(all) var totalDeposits: UFix64
    access(all) var totalPayouts: UFix64
    access(all) var activeUsers: UInt64
    
    access(all) struct VaultData {
        access(all) let totalPoolBalance: UFix64
        access(all) let totalDeposits: UFix64
        access(all) let totalPayouts: UFix64
        access(all) let activeUsers: UInt64
        
        init(
            totalPoolBalance: UFix64,
            totalDeposits: UFix64,
            totalPayouts: UFix64,
            activeUsers: UInt64
        ) {
            self.totalPoolBalance = totalPoolBalance
            self.totalDeposits = totalDeposits
            self.totalPayouts = totalPayouts
            self.activeUsers = activeUsers
        }
    }
    
    access(all) resource Administrator {
        
        access(all) fun emergencyWithdraw(amount: UFix64, recipient: Address) {
            pre {
                amount <= InsuranceVault.totalPoolBalance: "Insufficient vault balance"
            }
            
            let vaultRef = InsuranceVault.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
                from: /storage/flowTokenVault
            ) ?? panic("Could not borrow vault reference")
            
            let withdrawnVault <- vaultRef.withdraw(amount: amount)
            
            let recipientAccount = getAccount(recipient)
            let receiverRef = recipientAccount.capabilities.borrow<&{FungibleToken.Receiver}>(
                /public/flowTokenReceiver
            ) ?? panic("Could not borrow receiver reference")
            
            receiverRef.deposit(from: <-withdrawnVault)
            
            InsuranceVault.totalPoolBalance = InsuranceVault.totalPoolBalance - amount
        }
    }
    
    access(all) resource interface VaultPublic {
        access(all) fun deposit(from: @{FungibleToken.Vault}, depositor: Address)
        access(all) fun getVaultStats(): VaultData
    }
    
    access(all) resource Vault: VaultPublic {
        
        access(all) fun deposit(from: @{FungibleToken.Vault}, depositor: Address) {
            let amount = from.balance
            
            let vaultRef = InsuranceVault.account.storage.borrow<&FlowToken.Vault>(
                from: /storage/flowTokenVault
            ) ?? panic("Could not borrow vault reference")
            
            vaultRef.deposit(from: <-from)
            
            InsuranceVault.totalPoolBalance = InsuranceVault.totalPoolBalance + amount
            InsuranceVault.totalDeposits = InsuranceVault.totalDeposits + amount
            
            emit VaultDepositEvent(
                depositor: depositor,
                amount: amount,
                newBalance: InsuranceVault.totalPoolBalance,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun getVaultStats(): VaultData {
            return VaultData(
                totalPoolBalance: InsuranceVault.totalPoolBalance,
                totalDeposits: InsuranceVault.totalDeposits,
                totalPayouts: InsuranceVault.totalPayouts,
                activeUsers: InsuranceVault.activeUsers
            )
        }
    }
    
    access(account) fun payOut(user: Address, amount: UFix64) {
        pre {
            amount <= self.totalPoolBalance: "Insufficient vault balance for payout"
        }
        
        let vaultRef = self.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow vault reference")
        
        let withdrawnVault <- vaultRef.withdraw(amount: amount)
        
        let recipientAccount = getAccount(user)
        let receiverRef = recipientAccount.capabilities.borrow<&{FungibleToken.Receiver}>(
            /public/flowTokenReceiver
        ) ?? panic("Could not borrow receiver reference for user")
        
        receiverRef.deposit(from: <-withdrawnVault)
        
        self.totalPoolBalance = self.totalPoolBalance - amount
        self.totalPayouts = self.totalPayouts + amount
        
        emit VaultPayoutEvent(
            recipient: user,
            amount: amount,
            remainingBalance: self.totalPoolBalance,
            timestamp: getCurrentBlock().timestamp
        )
    }
    
    access(all) fun getVaultStats(): VaultData {
        return VaultData(
            totalPoolBalance: self.totalPoolBalance,
            totalDeposits: self.totalDeposits,
            totalPayouts: self.totalPayouts,
            activeUsers: self.activeUsers
        )
    }
    
    access(all) fun createVault(): @Vault {
        return <- create Vault()
    }
    
    init() {
        self.VaultStoragePath = /storage/FlowSureVault
        self.VaultPublicPath = /public/FlowSureVault
        
        self.totalPoolBalance = 0.0
        self.totalDeposits = 0.0
        self.totalPayouts = 0.0
        self.activeUsers = 0
        
        let admin <- create Administrator()
        self.account.storage.save(<-admin, to: /storage/FlowSureAdmin)
        
        let vault <- create Vault()
        self.account.storage.save(<-vault, to: self.VaultStoragePath)
        
        let vaultCap = self.account.capabilities.storage.issue<&Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)
    }
}
