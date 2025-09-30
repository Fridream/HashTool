#!/bin/bash

find_hashfile() {
    # IFS设置为空，防止前后空字符串被read去除
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local name="${file%.*}";local ext="${file##*.}"
        if [[ "${name,,}" == "md5" || "${ext,,}" == "md5" ]]; then
            mode="md5";HashFile="$file";return 0
        elif [[ "${name,,}" == "sha1" || "${ext,,}" == "sha1" ]]; then
            mode="sha1";HashFile="$file";return 0
        elif [[ "${name,,}" == "sha256" || "${ext,,}" == "sha256" ]]; then
            mode="sha256";HashFile="$file";return 0
        fi
    # <(...)临时创建文件，通过<重定向到read的stdin
    done < <(find . -maxdepth 1 -type f -printf "%f\n" 2>/dev/null)
    return 1
}

build_hash() {
    local HashFile="${mode^^}.hash";> "$HashFile"
    local total=$(find . -type f ! -name "$HashFile" | wc -l) count=0
    find . -type f ! -name "$HashFile" | sort | while IFS= read -r file; do
        local path=$(sed 's/\//\\/g' <<< "${file#./}");((count++))
        printf '%d/%d Building "%s" ...' "$count" "$total" "$path"
        local hash=$(${mode}sum "$file" | awk '{print $1}') # 提取第一列
        echo;echo "${hash}${key}${path}" >> "$HashFile"
    done;finish
}

check_hash() {
    [[ -z "$HashFile" ]] && read -p "请输入校验文件名：" HashFile;echo
    [[ ! -f "$HashFile" ]] && exit 0
    local check_num=1 has_miss=false has_error=false
    while IFS= read -r line; do
        line="${line%$'\r'}" # 去除windows可能留下的\r
        local hash="${line%%"$key"*}"
        local file="${line#*"$key"}"
        if [[ "$hash" == "$file" ]]; then
            printf '异常：%i: "%s"\n' "$check_num" "$line"
            echo "提示：间隔字符可能输入错误？";finish
        fi
        printf 'Checking "%s" ...' "$file";((check_num++))
        file="./$(sed 's/\\/\//g' <<< "${file}")"
        if [[ ! -f "$file" ]]; then
            echo "[MISS]";has_miss=true;continue
        fi
        local actual_hash=$(${mode}sum "$file" | awk '{print $1}')
        if [[ "$actual_hash" == "$hash" ]]; then
            echo "[RIGHT]"
        else
            echo "[FALSE]";has_error=true
        fi
    done < "$HashFile";echo
    if $has_error; then
        echo "- 存在严重异常问题！";finish
    fi
    if $has_miss; then
        echo "- 存在警告缺失问题？";finish
    fi
    echo "- 所有文件均无异常！";echo
    read -p "删除校验文件？" ans;[[ -z "$ans" ]] && ans="y"
    [[ "${ans,,}" == "y" ]] && rm -f "$HashFile"
    finish
}

finish() {
    echo;read -p "请按任意键继续. . . ";exit 0
}

# 开始执行
[[ -z "$1" ]] && exit 0
cd "$1" 2>/dev/null || exit 0
IFS= read -p "请输入间隔字符：" key
[[ -z "$key" ]] && key=" *"
if find_hashfile; then
    check_hash
fi
echo
read -p "请输入校验模式：" mode
[[ -z "$mode" ]] && mode="md5"
mode="${mode,,}"
echo
case "$mode" in
    md5|sha1|sha256) ;;
    *) exit 0 ;;
esac
read -p " 1.生成  2.解析   " action
echo
case "$action" in
    1) build_hash ;;
    2) check_hash ;;
    *) exit 0 ;;
esac