WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = (SELECT MIN(c2.c_custkey) FROM customer c2 WHERE c2.c_acctbal < ch.c_acctbal)
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
    HAVING order_value > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= '2022-01-01' OR o2.o_orderdate IS NULL)
),
RegionSummary AS (
    SELECT r.r_regionkey, COUNT(DISTINCT n.n_nationkey) AS nation_count, 
           COALESCE(SUM(CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal ELSE 0 END), 0) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey
)
SELECT 
    ch.c_name, 
    ch.level, 
    ps.p_name, 
    ps.total_cost, 
    ho.order_value, 
    rs.nation_count,
    CAST(NULLIF(ch.c_acctbal, 0) AS decimal(12, 2)) AS adjusted_balance
FROM CustomerHierarchy ch
FULL OUTER JOIN PartSupplier ps ON ch.c_custkey % 10 = ps.p_partkey % 10
LEFT JOIN HighValueOrders ho ON ho.o_orderkey = (SELECT MAX(o.o_orderkey) FROM HighValueOrders o WHERE o.order_value <= ch.c_acctbal)
JOIN RegionSummary rs ON rs.nation_count > 2 AND rs.total_supplier_balance BETWEEN ch.level * 1000 AND ch.level * 10000
WHERE ch.c_name ILIKE '%customer%'
ORDER BY ch.level, ps.total_cost DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
