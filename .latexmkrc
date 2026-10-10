# latexmk 配置：使用 LuaLaTeX 编译，自动按需调用 biber 并重复编译直至收敛
# latexmk config: compile with LuaLaTeX; biber and repeat passes run automatically

$pdf_mode = 4;  # 4 = lualatex

$lualatex = 'lualatex -interaction=nonstopmode -synctex=1 -file-line-error %O %S';

# 默认编译主文档 / Default target
@default_files = ('slide.tex');
