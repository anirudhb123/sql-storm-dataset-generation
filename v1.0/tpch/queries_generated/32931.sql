WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS hierarchy_level
    FROM supplier 
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 3
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
), PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    AVG(sh.s_acctbal) AS avg_account_balance,
    COALESCE(SUM(hv.o_totalprice), 0) AS total_high_value_orders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
LEFT JOIN HighValueOrders hv ON sh.s_suppkey = hv.o_custkey
LEFT JOIN PartSupplierInfo ps ON ps.rn = 1
GROUP BY n.n_name
HAVING AVG(sh.s_acctbal) IS NOT NULL
ORDER BY avg_account_balance DESC;
