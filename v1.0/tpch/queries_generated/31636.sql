WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderAmount AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
SupplierOrderSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(oa.total_amount) AS total_orders, COUNT(DISTINCT oa.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN OrderAmount oa ON p.p_partkey = oa.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT sos.s_suppkey, sos.s_name, sos.total_orders, sos.order_count,
           RANK() OVER (ORDER BY sos.total_orders DESC) AS rank_order,
           COUNT(sos.order_count) OVER () AS total_suppliers
    FROM SupplierOrderSummary sos
)
SELECT r.r_name, rs.s_name, rs.total_orders, 
       (CASE WHEN rs.order_count > 0 THEN ROUND(rs.total_orders / rs.order_count, 2) ELSE NULL END) AS avg_order_value,
       (SELECT COUNT(*) FROM SupplierHierarchy) AS hierarchy_size
FROM RankedSuppliers rs
JOIN nation n ON rs.s_suppkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name IS NOT NULL
ORDER BY rs.rank_order
LIMIT 10;
