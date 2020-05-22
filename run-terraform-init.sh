
[ -n "$BUCKET_STATE" ] || { echo >&2 $0: missing env var BUCKET; exit 1; }

echo $0: BUCKET_STATE=$BUCKET_STATE

terraform init -backend-config "bucket=$BUCKET_STATE"
