#!/bin/bash
# 使用 bash 实现的 flappyBird 小游戏
# 游戏坐标
# *--------------------->
# |                     x
# |
# |
# |
# |
# |
# V y

SCORE=0             # 游戏分数

GAME_OVER_FLAG=0    # 游戏结束标志
GAME_WIDTH=100      # 游戏内容宽（边框内部）
GAME_HEIGHT=20      # 游戏内容高（边框内部）
GAME_START_X=1      # 游戏内容起始列x坐标
GAME_START_Y=2      # 游戏内容起始行y坐标

PIPE="#"            # 管道的字符形状
PIPE_WIDTH=4        # 管道障碍物宽度
PIPE_HEIGHT_MIN=4   # 上下管道最小高度
PIPE_GAP=6          # 上下管道的间隔大小
PIPE_SPACE=20       # 管道间距，控制管道的生成速度
PIPE_MOVE_SPEED=2   # 管道的移动速度
PIPE_START_X=94     # 管道生成的起始列x坐标
PIPE_END_X=4        # 管道消失的结束列x坐标
PIPE_ARR_X=()       # 管道数组，记录每个管道的x坐标
PIPE_ARR_HEIGHT=()  # 管道数组，记录每个管道的缺口高度

GRAVITY=1           # 重力（下落速度）
JUMP=1              # 每次跳跃的高度
BIRD="@"            # 鸟🐦的图案
BIRD_X=$((10 + "$GAME_START_X"))           # 鸟的初始x轴位置（列）
BIRD_Y=$((("$GAME_HEIGHT" / 2) + "$GAME_START_Y"))  #居中（行）

# 绘制游戏边框
draw_border()
{
    printf "\n"
    for((i=$(("$GAME_WIDTH" + 2)) ; i>0 ; i--))
    do
        printf "="
    done
    printf "\n"
    for((i="$GAME_HEIGHT" ; i>0 ; i--))
    do
        printf "|"
        for((j="$GAME_WIDTH" ; j>0 ; j--))
        do
            printf " "
        done
        printf "|\n"
    done
    for((i=$(("$GAME_WIDTH" + 2)) ; i>0 ; i--))
    do
        printf "="
    done
}

# 绘制小鸟，接收键盘输入，更新小鸟🐦位置，根据小鸟全局变量的X,Y坐标绘制小鸟🐦
draw_bird()
{
    IFS= read -s -r -n 1 -t 0.01 char
    tput cup "$BIRD_Y" "$BIRD_X"
    printf " "
    case "$char" in
        ' ')
        # 输入空格，小鸟上升JNMP个高度
        BIRD_Y=$(("$BIRD_Y" - "$JUMP"))
        # 设置小鸟飞行高度上限
        if [[ "$BIRD_Y" -lt "$GAME_START_Y" ]] ; then
            BIRD_Y=$(("$GAME_START_Y"))
        fi
        ;;
        *)
        # 其他字符，小鸟下降GRAVITY个高度
        BIRD_Y=$(("$BIRD_Y" + "$GRAVITY"))
        ;;
    esac
    tput cup "$BIRD_Y" "$BIRD_X"
    printf "%s" "$BIRD"
}

# 随机生成柱子
generate_pipe()
{
    # 随机生成新柱子的高度
    pipe_height=$((RANDOM % ("$GAME_HEIGHT" - "$PIPE_GAP" - "$PIPE_HEIGHT_MIN" + 1) + "$PIPE_HEIGHT_MIN"))
    PIPE_ARR_X+=("$PIPE_START_X")
    PIPE_ARR_HEIGHT+=("$pipe_height")
}

# 提升管道绘制速度
# 提前生成一行管道
PIPE_SHAPE=""
for((t=0 ; t<"$PIPE_WIDTH" ; t++))
do
    PIPE_SHAPE+="$PIPE"
done
for((t=0 ; t<"$PIPE_MOVE_SPEED" ; t++))
do
    PIPE_SHAPE+=" "
done
# 提前生成一行空格
PIPE_GAP_SHAPE=""
for((t = 0; t<"$(("$PIPE_WIDTH" + "$PIPE_MOVE_SPEED"))" ; t++))
do
    PIPE_GAP_SHAPE+=" "
done

# 根据坐标绘制并更新柱子的画面
draw_pipe()
{
    # 获取管道数组长度，即管道个数
    pipe_count=${#PIPE_ARR_X[@]}
    # 移动光标绘制柱子
    for((i=0 ; i<"$pipe_count" ; i++))
    do
        # 移动坐标到对应的管道的起始位置
        cursor_y="$GAME_START_Y"
        cursor_x="${PIPE_ARR_X[i]}"
        tput cup "$cursor_y" "$cursor_x"
        # 按行绘制柱子
        for((j=0 ; j<"$GAME_HEIGHT" ; j++))
        do
            if [[ j -gt "${PIPE_ARR_HEIGHT[i]}" && j -lt "$(("${PIPE_ARR_HEIGHT[i]}" + "$PIPE_GAP"))" ]] ; then
                # 绘制上下管道之间的缺口
                printf "%s" "$PIPE_GAP_SHAPE"
            else
                # 绘制管道
                printf "%s" "$PIPE_SHAPE"
            fi
            # 换到下一行
            cursor_y="$(("$cursor_y" + 1))"
            tput cup "$cursor_y" "$cursor_x"
        done
    done
}

# 更新管道坐标，实现管道的移动，删除过时的管道坐标
update_pipe()
{
    if [[ "${PIPE_ARR_X[0]}" -le "$PIPE_END_X" ]] ; then
        # 截取数组，去除第0个元素
        PIPE_ARR_X=("${PIPE_ARR_X[@]:1}")
        PIPE_ARR_HEIGHT=("${PIPE_ARR_HEIGHT[@]:1}")
        # 清除游戏画面上残留的柱子
        cursor_y="$GAME_START_Y"
        cursor_x="$PIPE_END_X"
        tput cup "$cursor_y" "$cursor_x"
        for((i=0 ; i<"$GAME_HEIGHT" ; i++))
        do
            for((j=0 ; j<"$PIPE_WIDTH" ; j++))
            do
                printf " "
            done
            # 换到下一行
            cursor_y="$(("$cursor_y" + 1))"
            tput cup "$cursor_y" "$cursor_x"
        done
    fi
    # 遍历数组，修改x坐标
    pipe_count=${#PIPE_ARR_X[@]}
    for((i=0 ; i<"$pipe_count" ; i++))
    do
        tmp_x="${PIPE_ARR_X[i]}"
        tmp_x="$(("$tmp_x" - "$PIPE_MOVE_SPEED"))"
        PIPE_ARR_X[i]="$tmp_x"
    done
}

# 输出空格，清空原有游戏内容
clean_game()
{
    for((i=0 ; i<"$GAME_HEIGHT" ; i++))
    do
        tput cup $(("$i" + "$GAME_START_Y")) "$GAME_START_X"
        for((j=0 ; j<"$GAME_WIDTH" ; j++))
        do
            printf " "
        done
    done
}

# 碰撞检测及计分
check_collision()
{
    # 计分判断
    if [[ $(("${PIPE_ARR_X[0]}" + "$PIPE_WIDTH")) -lt "$BIRD_X" ]] ; then
        SCORE=$(("$SCORE" + 1))
        # 更新显示的分数
        tput cup 0 6
        printf "%d" "$SCORE"
    fi
    # 碰撞判断
    # 判断小鸟是否撞到柱子
    if [[ "$BIRD_X" -ge "${PIPE_ARR_X[0]}" && "$BIRD_X" -le $(("${PIPE_ARR_X[0]}" + "$PIPE_WIDTH")) ]] ; then
        if [[ "$BIRD_Y" -lt "${PIPE_ARR_HEIGHT[0]}" || "$BIRD_Y" -gt "$(("${PIPE_ARR_HEIGHT[0]}" + "$PIPE_GAP"))" ]] ; then
            GAME_OVER_FLAG="1"
        fi
    else
        # 判断小鸟是否撞到地
        if [[ "$BIRD_Y" -ge $(("$GAME_HEIGHT" + "$GAME_START_Y")) ]] ; then
            GAME_OVER_FLAG="1"
        fi
    fi
}

clear
tput civis  # 隐藏光标
tput cup 0 0
echo 'score:'"$SCORE"
tput cup 0 0

# 绘制游戏的边界
draw_border

# 提前生成一个柱子，避免后续判断出错
generate_pipe

# 游戏主循环
while [[ "$GAME_OVER_FLAG" -eq 0 ]]
do
    if [[ $(("${PIPE_ARR_X[-1]}" + "$PIPE_SPACE")) -lt "$PIPE_START_X" ]] ; then
        generate_pipe
    fi
    draw_pipe
    update_pipe
    draw_bird
    check_collision
    sleep 0.4
done

clean_game

tput reset
