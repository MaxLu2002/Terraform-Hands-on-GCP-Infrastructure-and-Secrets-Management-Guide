# 設定環境變數 (在此修改名稱)
export SA_NAME="terraform-gcp-cli-test"
export KEY_NAME="gcp_key"
p=$(gcloud config get-value project)
e="${SA_NAME}@$p.iam.gserviceaccount.com"
# 創建服務帳戶並下載金鑰
gcloud iam service-accounts create $SA_NAME || true
gcloud projects add-iam-policy-binding $p --member="serviceAccount:$e" --role="roles/editor"
gcloud iam service-accounts keys create $KEY_NAME.json --iam-account=$e
cloudshell download $KEY_NAME.json