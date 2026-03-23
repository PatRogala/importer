# Importer

```bash
=> rails data:generate[1000]
       user     system      total        real
   0.163371   0.030836   0.194207 (  0.213383)
```

```bash
=> rails data:import
       user     system      total        real
   3.178370   0.253669   3.432039 (  5.562357)
```

1. Setup attempt:

```bash
=> rails "data:generate[1000]"
       user     system      total        real
   0.123071   0.026656   0.149727 (  0.149920)
```

```bash
=> rails "data:import"
       user     system      total        real
   2.012763   0.140288   2.153051 (  2.426149)
```

## 1 Poprawka 1 insert zamiast zalewania bazy create

```bash
=> rails "data:import"
       user     system      total        real
   1.236214   0.093411   1.329625 (  1.497088)
```

## 2 Poprawka zamiana userów find or create by

```bash
=> rails "data:import"
       user     system      total        real
   0.052236   0.008567   0.060803 (  0.080048)
```

## 3 poprawka, rozbicie to na slice z myślą o większych zbiorach danych

1 Test dla miliona rekordów

```bash
=> rails "data:import"
       user     system      total        real
  46.276868   0.268088  46.544956 ( 46.592823)
```

## 4 poprawka skippowanie overheada do created/updated at, transakcja dla pojedynczego fsync

dla miliona:
```bash
=> rails "data:import"
       user     system      total        real
  30.657922   0.607842  31.265764 ( 52.911782)
```

## 5 dodanie lazy loadera
dla miliona:
```bash
=> rails "data:import"
       user     system      total        real
  29.679511   0.578192  30.257703 ( 50.677439)
```

## 6 to_h i pomijanie active modela dla usera:
dla miliona:
```bash
=> rails "data:import"
       user     system      total        real
  27.886029   0.509611  28.395640 ( 48.032127)
```
