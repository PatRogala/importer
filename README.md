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
