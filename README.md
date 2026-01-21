# A hands-on Lab of Vault（WindowOS實作指南）📒
本篇示範如何使用 Terraform 在 GCP 建立基礎資源（bucket、VPC、firewall、VM），並搭配 Vault 做金鑰/密鑰管理與存取驗證。內容包含環境安裝、建置流程、GCP 認證與 SSH 登入（含疑難排解）。
## Hands-on Lab
* 更詳細內容請參照[HackMD](https://hackmd.io/@mvFZJ_qaT5KyaJsJBsLz4Q/ByD2EoaHbg)
## 參考資源
- [Authenticating to Vault using Google Cloud IAM service accounts](https://hashicorp1674582558.zendesk.com/hc/en-us/articles/17325098124691-Authenticating-to-Vault-using-Google-Cloud-IAM-service-accounts)
- [Vault Plugin: Google Cloud Platform Auth Backend](https://github.com/hashicorp/vault-plugin-auth-gcp)
- [Authenticating to Vault using GCP GCE single Instance Signed Metadata](https://support.hashicorp.com/hc/en-us/articles/7999558729619-Authenticating-to-Vault-using-GCP-GCE-single-Instance-Signed-Metadata)
## 環境需求
- Windows OS
- Vault、Terraform、Google Cloud SDK (gcloud)
- 已建立的 GCP 專案
## 📒1. 前置安裝
1. **檢查 Winget（Windows 內建，通常無需安裝）**
在 PowerShell 中輸入以下指令確認工具是否可用：
```powershell
winget --version
```
*若無法執行，請至 Microsoft Store 更新「應用程式安裝程式」。*

2. **安裝 Vault, Terraform 與 Google Cloud SDK**
```powershell
winget install HashiCorp.Vault
winget install HashiCorp.Terraform
winget install Google.CloudSDK
```
3. **重啟 Terminal 後執行驗證：**
```powershell
vault --version; terraform --version; gcloud --version
```
## 📒2. 在GCP上建立Service Account並取得權限
* 進入GCP Console並打開Cloud Shell
* 在Cloud Shell輸入以下指令，這指令會幫你
    1. 建立名為`terraform-gcp-cli-test` 的 service account
    2. 賦予 `editor` 權限
    3. 下載Account Key，可以幫助你建立Terraform資源
```powershell
# 設定環境變數 (在此修改名稱)
$SA_NAME="terraform-gcp-cli-test"
$KEY_NAME="gcp_key"
$p=$(gcloud config get-value project)
$e="$SA_NAME@$p.iam.gserviceaccount.com"
# 創建服務帳戶並下載金鑰
gcloud iam service-accounts create $SA_NAME || $true
gcloud projects add-iam-policy-binding $p --member="serviceAccount:$e" --role="roles/editor"
gcloud iam service-accounts keys create "$KEY_NAME.json" --iam-account=$e
cloudshell download "$KEY_NAME.json"
```
3. 把`gcp_key.json`存到 `./gcp_infra/files/`


## 📒3. 使用 Terraform 建置 GCP 基礎架構
切換到 gcp_infra 目錄
1. 進入`main.tf`確認要建立的資源是否正確

2. 進入`terraform.tfvars`確認參數是否正確

3. 執行以下程式碼建立資源：
```powershell
terraform init; terraform plan; terraform apply -auto-approve
```

執行成功後，Terraform 會輸出類似的資訊（示例）：

*上述 output 提供了用來登入 GCP 與 VM 的建議指令，強烈建議開一個`.sh`檔案把這串複製下來。*

## 📒4. gcloud 認證與驗證
複製並執行`"gcloud_login_command"`，使用 service account key 進行認證（範例，請確認路徑與檔名正確）：
```powershell
gcloud auth activate-service-account --key-file="./files/gcp_key.json"
gcloud config set project {YOUR-PROJECT-ID}
```

驗證是否成功：
```powershell
Write-Output "\n--- Active Account ---"; gcloud config get-value account; Write-Output "\n--- Project List ---"; gcloud projects list
```
*出現上圖有列出正確的`project_id`就算成功*

## 📒5. SSH 登入VM方法

### 📘1. 手動產生金鑰並以私鑰 SSH 登入
產生一個名為"terraform_test" 的RSA 金鑰對：
```powershell
New-Item -ItemType Directory -Path "keys" -Force; ssh-keygen --% -t rsa -b 4096 -f ".\keys\id_rsa" -N "" -C "terraform_test"
```
將公鑰上傳到 VM metadata（或以其他方式上傳），再用私鑰連線：
* 選 compute engine -> 你的VM -> edit -> SSH keys的Add item
* 貼上公鑰後儲存
* 在VM的metadata有看到就表示成功了，這組username要複製下來，像我這邊就要複製`maxlu`

* 請將 {user} 與 {external_ip} 換成實際值。
```powershell
ssh -i ./keys/id_rsa {user}@{external_ip}
```
---
#### 💡常見錯誤與排查（OS Login 與 Metadata）
如果已經手動上傳的金鑰但無法登入，常見原因是 OS Login 功能Enable了，解決方法如下。
*(如果想知道OS Login是什麼可以看[這裡](https://docs.cloud.google.com/compute/docs/oslogin?hl=zh-tw))*
1. 檢查專案是否啟用 OS Login：
```powershell
gcloud compute project-info describe --format="value(commonInstanceMetadata.items.enable-oslogin)"
```
2. 若回傳 true，手動上傳的 Metadata 金鑰會被忽略。處理方式：
    - 關閉 OS Login（允許 metadata 金鑰生效）：
```powershell
gcloud compute project-info add-metadata --metadata enable-oslogin=FALSE
```
3. 重新輸入一樣的指令，就可以成功進入了
```powershell
ssh -i ./keys/id_rsa {user}@{external_ip}
```

如欲啟用 OS Login（較安全，讓 IAM 與 OS Login 結合）：
```powershell
gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE
```
---
### 📘 2. 使用 gcloud 自動處理金鑰（推薦）
* 執行以下指令
```powershell
gcloud compute ssh max-public-gce-instance --zone=us-west1-c --quiet
```
* 當我們第一次使用 gcloud compute SSH 指令時，gcloud 會自動為我們建立一組 SSH key 並存放在本機目錄內
*gcloud 會自動在本機產生公私鑰並上傳至 Instance metadata，基本上這個方法不用做甚麼額外的設定*



## 📒小結📒
- 建議以 gcloud compute ssh 為首選（自動金鑰管理、較少設定錯誤）。
- 若使用 metadata 手動上傳金鑰，請確認 OS Login 狀態與專案設定。
- Terraform 建置後 output 會提供登入與驗證指令，依照輸出指令進行即可。