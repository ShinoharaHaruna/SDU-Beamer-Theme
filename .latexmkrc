# latexmk 配置：使用 XeLaTeX 编译，自动按需调用 biber 并重复编译直至收敛
# latexmk config: compile with XeLaTeX; biber and repeat passes run automatically

$pdf_mode = 5;  # 5 = xelatex

$xelatex = 'xelatex -interaction=nonstopmode -synctex=1 -file-line-error %O %S';

# 默认编译主文档 / Default target
@default_files = ('slide.tex');
