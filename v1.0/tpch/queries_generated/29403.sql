WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM part p
    WHERE p.p_retailprice > 100.00
), TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000.00
), PartSupplyDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        pp.p_name
    FROM partsupp ps
    JOIN RankedParts pp ON ps.ps_partkey = pp.p_partkey
), OrdersTotals AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    R.p_name, 
    R.p_brand, 
    R.p_retailprice, 
    T.s_name AS supplier_name, 
    T.nation_name, 
    S.total_price
FROM RankedParts R
JOIN PartSupplyDetails P ON R.p_partkey = P.ps_partkey
JOIN TopSuppliers T ON P.ps_suppkey = T.s_suppkey
JOIN OrdersTotals S ON S.total_price > 10000.00
WHERE R.rank <= 3
ORDER BY R.p_brand, R.p_retailprice DESC, T.s_name;
