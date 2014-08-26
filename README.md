futurestocks
============

Run tests:
```
git clone https://github.com/johannespetzold/futurestocks
cd futurestocks
bundle
bundle exec rake
```

Run server:
```
cd futurestocks
bundle
bundle exec rake server
```

Sample query against server:
```
curl -i -X POST localhost:4567/stock_prices?symbol=AMAZINGSTOCK -d '1462558650,2024.26
1462645050,2022.18
1462731450,2020.44
1462817850,2001.90
1462904250,2033.34
1462990650,2060.54
1463077050,2064.16
1463163450,2068.08'
```
