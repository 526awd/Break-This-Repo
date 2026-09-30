HAI 1.2
BTW ==========================================================================
BTW   SECURITY.lol —— Break-This-Repo 安全政策（可执行版）
BTW
BTW   跑法:  python LOLCODE/lolrun.py LOLCODE/SECURITY.lol
BTW ==========================================================================


HOW IZ I 危险吗 YR 行为
    BOTH SAEM 行为 AN "往 CI 里塞后门"
    O RLY?
        YA RLY
            FOUND YR WIN
    OIC
    BOTH SAEM 行为 AN "扬了自动合并工作流"
    O RLY?
        YA RLY
            FOUND YR WIN
    OIC
    BOTH SAEM 行为 AN "把别人的密钥提交进仓库"
    O RLY?
        YA RLY
            FOUND YR WIN
    OIC
    FOUND YR FAIL
IF U SAY SO


HOW IZ I 报一行 YR 行为
    VISIBLE SMOOSH "    " AN 行为 AN " ... " MKAY
    I IZ 危险吗 YR 行为 MKAY
    O RLY?
        YA RLY
            VISIBLE "        [!] 这是安全事件，不是乐子。"
        NO WAI
            VISIBLE "        [ ] 无害。"
    OIC
IF U SAY SO


VISIBLE "############################################################"
VISIBLE "#                                                          #"
VISIBLE "#        Break-This-Repo  安全政策  ·  LOLCODE 版           #"
VISIBLE "#                                                          #"
VISIBLE "############################################################"
VISIBLE ""
VISIBLE "  本仓库的威胁模型只有一句话："
VISIBLE "    这个仓库会自动合并任何没有冲突的 PR。"
VISIBLE ""
VISIBLE "  所以真正的安全问题不是「有人改坏了一个文件」，"
VISIBLE "  而是「有人利用了自动合并本身」。"
VISIBLE ""
VISIBLE "  逐项审计："
VISIBLE ""

I IZ 报一行 YR "往 CI 里塞后门" MKAY
I IZ 报一行 YR "扬了自动合并工作流" MKAY
I IZ 报一行 YR "把别人的密钥提交进仓库" MKAY
I IZ 报一行 YR "把 README 翻译成 LOLCODE" MKAY

VISIBLE ""
VISIBLE "  结论："
VISIBLE "    .github/ 受保护，所以前两项现在打不通。"
VISIBLE "    第三项永远是真问题 —— 别提交别人的密钥。"
VISIBLE "    第四项是本仓库的主要用途。"
VISIBLE ""
VISIBLE "  免责声明："
VISIBLE "    本仓库所有文件均为 'AS-IS' 提供。"
VISIBLE "    在 LOLCODE 里 'AS-IS' 写作 'AS-IZ'，但意思一样。"
VISIBLE ""
VISIBLE "  上报方式："
VISIBLE "    在 issue 里写一句 HAI，然后等。"
VISIBLE ""
VISIBLE "  KTHXBAI."

KTHXBAI
