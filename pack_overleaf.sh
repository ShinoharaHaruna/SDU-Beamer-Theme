#!/usr/bin/env bash
# 打包 SDU-Beamer-Theme 为可上传 Overleaf 的 zip
#
# Overleaf 免费版时限实测结论 (2026-10):
#   * 免费版首编主要瓶颈是 biblatex/biber 与 CJK 字体缓存, 均为一次性开销
#   * 超时后多点几次 Recompile 可能通过——字体/pk 缓存在项目内保留
#
# 各变体在免费版 Overleaf 的可用性:
#   [可用]   ./pack_overleaf.sh --no-bib              XeLaTeX 精简包, Fandol 四字体,
#            中文任意位置可用. 推荐主推.
#   [可用]   ./pack_overleaf.sh --pdflatex --no-bib   pdfLaTeX 精简包, CJKutf8+gbsn
#            单一宋体, 中文仅限正文, 元数据/章节名需英文. 备胎方案.
#   [不可用] 任何带 biblatex 的组合                    biber+收敛编译超时限
#   [不可用] --full (含 --lite/--no-bib 任意组合)      33-38 页超出免费版体量上限
#   [本地]   --with-fonts                             300MB 字体, 仅本地有意义
#
# 用法:
#   ./pack_overleaf.sh              精简包（默认）: 不含 fonts/, slide.tex 为精简示例,
#                                    Fandol 字体方案, 面向免费版 Overleaf
#   ./pack_overleaf.sh --pdflatex   精简包改用 pdfLaTeX + CJKutf8(gbsn), 不建 fontspec 缓存
#   ./pack_overleaf.sh --no-bib     去掉 biblatex/biber 与参考文献页(可与 --pdflatex/--full 叠加)
#   ./pack_overleaf.sh --lite       配合 --full: 删掉 tikz 绘图与代码高亮 frame 减重
#   ./pack_overleaf.sh --full       完整包: 使用仓库原 slide.tex, 仍切 Fandol 字体
#   ./pack_overleaf.sh --with-fonts 完整包 + fonts/ (~300MB), 保留 LXGW/更纱字体
#   ./pack_overleaf.sh -o out.zip   指定输出文件名
set -euo pipefail
cd "$(dirname "$0")"

FULL=0
WITH_FONTS=0
PDFLATEX=0
NO_BIB=0
LITE=0
OUT="SDU-Beamer-Theme-overleaf.zip"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pdflatex)   PDFLATEX=1; shift ;;
        --no-bib)     NO_BIB=1; shift ;;
        --lite)       LITE=1; shift ;;
        --full)       FULL=1; shift ;;
        --with-fonts) WITH_FONTS=1; FULL=1; shift ;;
        -o|--output)  OUT="$2"; shift 2 ;;
        -h|--help)    sed -n '2,25p' "$0"; exit 0 ;;
        *) echo "未知参数: $1" >&2; exit 1 ;;
    esac
done

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
PKG="$STAGE/SDU-Beamer-Theme"
mkdir -p "$PKG/img/Example"

cp -p ref.bib README.md *.sty "$PKG/"
cp -p img/Example/SDU.png img/Example/SimpleDistributedStorageArchitecture.png "$PKG/img/Example/"

# eps 每次编译都要走 epstopdf 转换, 预转为 pdf
if [[ ! -f img/Example/SDU.pdf ]]; then
    epstopdf img/Example/SDU.eps img/Example/SDU.pdf 2>/dev/null \
        || gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=img/Example/SDU.pdf img/Example/SDU.eps
fi
cp -p img/Example/SDU.pdf "$PKG/img/Example/"

if [[ $FULL -eq 1 ]]; then
    cp -p slide.tex "$PKG/slide.tex"
    sed -i 's|img/Example/SDU\.eps|img/Example/SDU.pdf|g' "$PKG/slide.tex"
else
    # 精简示例: 独立生成, 不修改仓库 slide.tex
    if [[ $PDFLATEX -eq 1 ]]; then
    cat > "$PKG/slide.tex" <<'EOF'
% SDU-Beamer-Theme -- 山东大学 Beamer 主题精简示例
% 完整版(含参考文献、代码高亮、TikZ 示例与 LXGW/更纱字体)见:
%   https://github.com/ShinoharaHaruna/SDU-Beamer-Theme
% 本文件面向 Overleaf 免费版: pdfLaTeX + CJKutf8(gbsn), 不加载 biblatex.
% 本地编译请用仓库原版 slide.tex + latexmk(XeLaTeX).
\documentclass[aspectratio=169]{beamer}

% 中文支持: pdfLaTeX + CJKutf8 (gbsn 文鼎宋体), 无须 fontspec 字体缓存
\usepackage{CJKutf8}
\usepackage{newtxtext} % Times 风格英文字体

% 参考文献 / Bibliography
\usepackage[style=numeric-comp, backend=biber]{biblatex}
\addbibresource{ref.bib}
EOF
    else
    cat > "$PKG/slide.tex" <<'EOF'
% SDU-Beamer-Theme -- 山东大学 Beamer 主题精简示例
% 完整版(含参考文献、代码高亮、TikZ 示例与 LXGW/更纱字体)见:
%   https://github.com/ShinoharaHaruna/SDU-Beamer-Theme
% 本文件面向 Overleaf 免费版: XeLaTeX + xeCJK(Fandol), 不加载 biblatex.
% 本地编译请用仓库原版 slide.tex + latexmk(XeLaTeX).
\documentclass[aspectratio=169]{beamer}

% 字体设置 / Font settings
\usepackage{fontspec} % 字体选择 / Font selection
\usepackage{xeCJK} % 中文字体支持 / Chinese font support

% Fandol 方案, Overleaf 自带, 无须自定义字体
\setCJKsansfont{FandolHei}[
  BoldFont = FandolHei-Bold
]
\setCJKmainfont{FandolSong}[
  BoldFont = FandolSong-Bold,
  ItalicFont = FandolKai,
  BoldItalicFont = FandolKai
]
\setCJKmonofont{FandolFang}

% 英文字体 / English fonts
\setmainfont{Times New Roman}
\setsansfont{Arial}

% 参考文献 / Bibliography
\usepackage[style=numeric-comp, backend=biber]{biblatex}
\addbibresource{ref.bib}
EOF
    fi
    cat >> "$PKG/slide.tex" <<'EOF'
\usetheme{SDU} % 山大主题 / SDU theme

\author{山东大学某某}
\title{SDU Beamer Theme}
\subtitle{山大风格 Beamer 模板}
\institute{山东大学 某学院}
\date{\today}

\begin{document}

% 标题页 / Title page
\begin{frame}
    \titlepage
    \begin{figure}[htpb]
        \begin{center}
            \includegraphics[width=0.1\linewidth]{img/Example/SDU.pdf}
        \end{center}
    \end{figure}
\end{frame}

% 目录页 / Table of contents
\begin{frame}
    \tableofcontents
\end{frame}

\section{简介}

\begin{frame}{模板简介}
    \begin{itemize}
        \item 山东大学 Beamer 主题, 主色为山大红
        \item 适用于学术报告、论文答辩与课堂展示
        \item 本精简示例可直接在 Overleaf 免费版编译
    \end{itemize}
\end{frame}

\section{排版示例}

\begin{frame}{列表与块环境}
    \begin{columns}
        \column{0.5\textwidth}
        \begin{itemize}
            \item 无序列表第一项
            \item 无序列表第二项
        \end{itemize}
        \begin{enumerate}
            \item 有序列表第一项
            \item 有序列表第二项
        \end{enumerate}
        \column{0.5\textwidth}
        \begin{block}{普通块}
            块环境正文
        \end{block}
        \begin{alertblock}{警示块}
            警示块正文
        \end{alertblock}
        \begin{exampleblock}{示例块}
            示例块正文
        \end{exampleblock}
    \end{columns}
\end{frame}

\begin{frame}{数学公式}
    麦克斯韦方程组:
    \begin{align}
        \nabla\cdot\mathbf{E}  & = \frac{\rho}{\varepsilon_0} \\
        \nabla\times\mathbf{B} & = \mu_0\mathbf{J}
            + \mu_0\varepsilon_0\frac{\partial\mathbf{E}}{\partial t}
    \end{align}
\end{frame}

\begin{frame}{三线表与插图}
    \begin{columns}
        \column{0.5\textwidth}
        \begin{table}
            \begin{tabular}{lcc}
                \toprule
                项目 & 甲 & 乙 \\
                \midrule
                行一 & 1 & 2 \\
                行二 & 3 & 4 \\
                \bottomrule
            \end{tabular}
        \end{table}
        \column{0.5\textwidth}
        \begin{figure}
            \includegraphics[width=0.55\linewidth]{img/Example/SDU.pdf}
        \end{figure}
    \end{columns}
\end{frame}

\section{参考文献}

\begin{frame}[allowframebreaks]{参考文献}
    \nocite{*}
    \printbibliography
\end{frame}

% 致谢页 / Thanks page
\begin{frame}
    \begin{center}
        {\Huge\calligra Thanks!}
    \end{center}
\end{frame}

\end{document}
EOF
    if [[ $PDFLATEX -eq 1 ]]; then
        # CJKutf8 需要把中文内容包进 CJK 环境
        sed -i \
            -e 's|^\\begin{document}|\\begin{document}\n\\begin{CJK}{UTF8}{gbsn}|' \
            -e 's|^\\end{document}|\\end{CJK}\n\\end{document}|' \
            "$PKG/slide.tex"
        # 会进入书签/元数据/目录的命令用英文, 避免在 CJK 环境外展开中文
        sed -i \
            -e 's|\\author{山东大学某某}|\\author{Your Name}|' \
            -e 's|\\subtitle{山大风格 Beamer 模板}|\\subtitle{SDU Beamer Theme Demo}|' \
            -e 's|\\institute{山东大学 某学院}|\\institute{Shandong University}|' \
            -e 's|\\section{简介}|\\section{Introduction}|' \
            -e 's|\\section{排版示例}|\\section{Demo}|' \
            -e 's|\\section{参考文献}|\\section{References}|' \
            "$PKG/slide.tex"
        # 在模板简介 frame 中说明 pdfLaTeX 变体的限制
        sed -i 's|\\item 本精简示例可直接在 Overleaf 免费版编译|&\n        \\item 本页为 pdfLaTeX 变体: 中文仅限正文(单一宋体), 章节名与作者信息需用英文; 完整功能请改用 XeLaTeX 版本|' "$PKG/slide.tex"
    else
        # 在模板简介 frame 中说明 XeLaTeX 变体的说明
        sed -i 's|\\item 本精简示例可直接在 Overleaf 免费版编译|&\n        \\item 本页为 XeLaTeX 变体: xeCJK + Fandol 字体(宋/黑/楷/仿宋), 中文可用于任意位置; 不含参考文献, 完整版见 GitHub 仓库|' "$PKG/slide.tex"
    fi
fi

if [[ $NO_BIB -eq 1 ]]; then
    # 去掉 biblatex/biber 与参考文献页, 少一遍 biber 和收敛编译
    sed -i \
        -e '/^\\usepackage\[style=numeric-comp, backend=biber\]{biblatex}/d' \
        -e '/^\\addbibresource{ref.bib}/d' \
        "$PKG/slide.tex"

    python3 - "$PKG/slide.tex" <<'PYEOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
# 完整版: \\subsection{参考文献} 起的引用 frame 和 printbibliography frame 一并去掉
s = re.sub(r'\\subsection\{参考文献\}.*?\\printbibliography\s*\n\\end\{frame\}\n', '', s, flags=re.S)
# 精简版: \\section{References}/\\section{参考文献} 起的 printbibliography frame
s = re.sub(r'\\section\{(References|参考文献)\}.*?\\printbibliography\s*\n\\end\{frame\}\n', '', s, flags=re.S)
# 删掉残留的 \\cite{...} (如历史沿革页)
s = re.sub(r'\\cite\{[^}]*\}', '', s)
# 去掉参考文献后, 合并章节标题不再提及它
s = s.replace('\\section{代码与参考文献}', '\\section{代码}')
open(p, 'w').write(s)
PYEOF
fi

if [[ $LITE -eq 1 && $FULL -eq 1 ]]; then
    # 轻量完整版: 删掉含 lstlisting / tikzpicture 的 frame, 以及因此空掉的章节标题
    python3 - "$PKG/slide.tex" <<'PYEOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
# 逐 frame 删除包含 lstlisting 或 tikzpicture 的
frame_re = re.compile(r'\\begin\{frame\}.*?\\end\{frame\}\n?', re.S)
def heavy(m):
    body = m.group(0)
    return 'lstlisting' in body or 'tikzpicture' in body
s = frame_re.sub(lambda m: '' if heavy(m) else m.group(0), s)
# 反复删掉后面紧跟另一个章节标题或文档结尾的空 \\subsection / \\section
for _ in range(10):
    s2 = re.sub(r'\\subsection\{[^}]*\}\s*(?=\\subsection|\\section|\\end\{document\})', '', s)
    s2 = re.sub(r'\\section\{[^}]*\}\s*(?=\\section|\\end\{document\})', '', s2)
    if s2 == s:
        break
    s = s2
open(p, 'w').write(s)
PYEOF
fi

if [[ $WITH_FONTS -eq 1 ]]; then
    cp -rp fonts "$PKG/"
elif [[ $FULL -eq 1 ]]; then
    # 完整包(无字体): 切到 Fandol 方案
    f="$PKG/slide.tex"
    sed -i \
        -e 's|^\\setCJKsansfont\[AutoFakeBold\]{LXGW WenKai}|% &|' \
        -e 's|^\\setCJKmainfont{LXGW WenKai}|% &|' \
        -e 's|^\\setCJKmonofont{Sarasa Mono SC}|% &|' \
        -e '/^% \\setCJKsansfont{FandolHei}/,/^% \\setCJKmonofont{FandolFang}/s/^% //' \
        "$f"
fi

( cd "$STAGE" && zip -rq "$OLDPWD/$OUT" SDU-Beamer-Theme )

SIZE=$(du -h "$OUT" | cut -f1)
echo "已生成: $OUT ($SIZE)"
if [[ $PDFLATEX -eq 1 ]]; then
    echo "精简包(pdfLaTeX): 已用 CJKutf8/gbsn, 上传后请将 Overleaf Compiler 设为 pdfLaTeX"
elif [[ $FULL -eq 0 ]]; then
    echo "精简包: slide.tex 为精简示例, Fandol 字体, 面向免费版 Overleaf"
elif [[ $WITH_FONTS -eq 0 ]]; then
    echo "完整包: 仓库 slide.tex, 已切换为 Fandol 字体, 未含 fonts/"
else
    echo "完整包: 含 fonts/ (~300MB), 注意 Overleaf 免费版项目空间限制"
fi
