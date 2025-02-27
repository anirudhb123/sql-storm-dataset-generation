WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost,
           CASE WHEN p.p_retailprice - ps.ps_supplycost > 0 THEN 'Profitable' ELSE 'Non-profitable' END AS profitability
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
TotalSales AS (
    SELECT l.l_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT p.p_name, 
       COALESCE(ts.total_sales, 0) AS total_sales, 
       hp.profitability, 
       rs.s_name, 
       rs.s_acctbal
FROM HighValueParts hp
LEFT JOIN TotalSales ts ON hp.p_partkey = ts.l_partkey
LEFT JOIN RankedSuppliers rs ON rs.rank = 1
WHERE hp.p_retailprice > 50
  AND (hp.profitability = 'Profitable' OR hp.profitability IS NULL)
ORDER BY total_sales DESC, hp.p_name;
