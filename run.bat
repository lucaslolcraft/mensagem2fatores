:: run.bat

@echo off
echo Iniciando o app Flutter em modo web na porta 5000...
echo O localStorage sera persistente nesta sessao.

flutter run -d chrome --web-port=5000

echo.
pause