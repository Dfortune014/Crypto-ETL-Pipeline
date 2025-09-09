resource "aws_iam_role" "lambda_exec" {
  name = "lambda-s3-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

data "aws_iam_policy_document" "lambda_s3_put" {
  statement {
    sid     = "AllowWriteToArchive"
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:PutObjectTagging"]
    resources = [
      "${aws_s3_bucket.archive.arn}/raw/*",
      "${aws_s3_bucket.archive.arn}/processed/*"
    ]
  }
  statement {
    sid       = "AllowListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.archive.arn]
  }
}

resource "aws_iam_policy" "lambda_s3_put" {
  name   = "lambda-s3-put-${var.environment}"
  policy = data.aws_iam_policy_document.lambda_s3_put.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_s3_put" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_put.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
