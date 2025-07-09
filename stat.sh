#!/bin/bash

# 输出文件
output_file="commits.json"

# 初始化 JSON 数组
echo "[" > "$output_file"

# 遍历所有子目录
find . -type d -exec test -d {}/.git \; -print | while read -r dir; do
  # 进入目录
  cd "$dir" || continue

  # 获取 Git 信息
  branch=$(git rev-parse --abbrev-ref HEAD)
  commit_hash=$(git rev-parse HEAD)
  commit_message=$(git log -1 --pretty=%B | head -n 1)
  author=$(git log -1 --pretty=%an)
  email=$(git log -1 --pretty=%ae)
  date=$(git log -1 --pretty=%cd --date=iso)

  # 打印信息
  echo "Repository: $dir"
  echo "Branch: $branch"
  echo "Commit Hash: $commit_hash"
  echo "Message: $commit_message"
  echo "Author: $author <$email>"
  echo "Date: $date"
  echo

  # 写入 JSON
  cat <<EOF >> "$output_file"
  {
    "repository": "$dir",
    "branch": "$branch",
    "commit_hash": "$commit_hash",
    "commit_message": "$commit_message",
    "author": "$author",
    "email": "$email",
    "date": "$date"
  },
EOF

  # 返回上一级目录
  # shellcheck disable=SC2164
  cd - > /dev/null
done

# 移除最后一个逗号并关闭 JSON 数组
sed -i '$ s/,$//' "$output_file"
echo "]" >> "$output_file"

echo "Git repository information has been saved to $output_file"