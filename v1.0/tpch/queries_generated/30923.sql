WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 0 AS level
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
SupplierPart AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 
           p.p_name, s.s_name,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
SalesStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           SUM(l.l_extendedprice * (1 - l.l_discount)) / COUNT(DISTINCT l.l_orderkey) AS avg_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey
)
SELECT ch.c_name, ch.c_acctbal, sp.p_name, sp.s_name, st.total_sales, st.avg_sales
FROM CustomerHierarchy ch
LEFT JOIN SupplierPart sp ON sp.rn = 1
LEFT JOIN SalesStats st ON st.o_orderkey = ch.c_custkey
WHERE (ch.c_acctbal - COALESCE(st.total_sales, 0)) > 1000
  AND sp.ps_availqty > 0
ORDER BY ch.c_acctbal DESC, total_sales DESC
LIMIT 50;
