## ⚠️ Caution

> ⚠️ **Warning:** This repository contains scripts that interact with live Exchange Online and other production environments.  
> 🧪 Always review the code thoroughly before executing any script.   
> 🛡️ Use test environments whenever possible.  
> 🧑‍💻 You are solely responsible for the outcomes — use at your own risk!

# PowerShell Scripts for Exchange Online

This repository contains PowerShell scripts to automate and manage tasks in **Exchange Online**, part of Microsoft 365. These scripts use the Exchange Online PowerShell module to connect, query, and administer mailboxes, groups, policies, and more.

## 💻 Prerequisites

Before using these scripts, make sure you have:

- Windows PowerShell 5.1 or PowerShell 7+
- [Exchange Online PowerShell V2 Module (EXO V2)](https://learn.microsoft.com/powershell/exchange/exchange-online-powershell-v2)
- [About the Exchange Online PowerShell module](https://learn.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps)
- Global Admin or Exchange Admin role in Microsoft 365

## 🔧 Installation

Install the Exchange Online module if you haven't already:

```powershell
Install-Module -Name ExchangeOnlineManagement

Or update it:
Update-Module ExchangeOnlineManagement

🔐 Connect to Exchange Online (EXO V2/V3)

Connect-ExchangeOnline -UserPrincipalName youradmin@domain.com

To disconnect:
Disconnect-ExchangeOnline


📁 Available Scripts


✅ Best Practices
Run scripts from PowerShell 7+ for best compatibility.
Always test in a non-production environment.


**⚠️ Caution: Use At Your Own Risk**
