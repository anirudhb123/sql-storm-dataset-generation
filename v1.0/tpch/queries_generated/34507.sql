WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(COALESCE(os.total_sales, 0)) AS total_order_sales,
    COUNT(DISTINCT sh.s_suppkey) AS active_suppliers,
    AVG(psd.ps_supplycost) AS avg_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN OrderSummary os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_nationkey = n.n_nationkey
)
LEFT JOIN PartSupplierDetails psd ON psd.rn = 1 AND psd.ps_availqty > 0
GROUP BY r.r_name, n.n_name
HAVING AVG(psd.ps_supplycost) IS NOT NULL
ORDER BY total_order_sales DESC;
