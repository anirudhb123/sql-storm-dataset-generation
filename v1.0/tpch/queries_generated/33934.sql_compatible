
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, CONCAT(s.s_name, ' - Sub'), s.s_acctbal * 0.9, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 2
),
PartCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, pc.total_cost
    FROM part p
    JOIN PartCost pc ON p.p_partkey = pc.ps_partkey
    ORDER BY pc.total_cost DESC
    LIMIT 5
),
OrderSummary AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS lineitem_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY o.o_orderkey
),
MaxRevenue AS (
    SELECT MAX(total_revenue) AS max_revenue
    FROM OrderSummary
)
SELECT 
    th.p_name,
    th.total_cost,
    os.o_orderkey,
    os.lineitem_count,
    os.total_revenue,
    sr.s_name AS supplier_name,
    sr.level AS supplier_level
FROM TopParts th
LEFT JOIN OrderSummary os ON th.p_partkey = os.o_orderkey
CROSS JOIN SupplierHierarchy sr
WHERE th.total_cost > (SELECT max_revenue FROM MaxRevenue) 
AND sr.s_acctbal IS NOT NULL
ORDER BY th.total_cost DESC, os.total_revenue DESC;
