WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size > 10
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       COALESCE(SUM(pl.p_total_price), 0) AS total_part_value,
       COALESCE(SUM(tl.total_revenue), 0) AS total_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS p_total_price
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    GROUP BY ps.ps_partkey
) pl ON pl.ps_partkey IN (SELECT p.p_partkey FROM FilteredParts p WHERE p.rn <= 5)
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN TotalLineItems tl ON tl.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;

