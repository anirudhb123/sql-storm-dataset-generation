
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RegionCounts AS (
    SELECT r.r_regionkey, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
),
AvgLineItemPrice AS (
    SELECT o.o_orderkey, AVG(l.l_extendedprice) AS avg_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 5
)
SELECT 
    r.r_regionkey, 
    r.nation_count,
    COALESCE(avg.avg_price, 0) AS average_line_item_price,
    COALESCE(th.total_cost, 0) AS top_supplier_cost
FROM RegionCounts r
LEFT JOIN AvgLineItemPrice avg ON r.r_regionkey = avg.o_orderkey
LEFT JOIN TopSuppliers th ON r.r_regionkey = th.s_suppkey
WHERE r.nation_count > 0
ORDER BY r.r_regionkey DESC, average_line_item_price DESC;
