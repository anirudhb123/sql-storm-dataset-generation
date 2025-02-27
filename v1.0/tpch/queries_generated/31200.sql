WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN SupplierHierarchy sh ON sh.s_suppkey = ps.ps_partkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
OrderTotals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
),
TopRegions AS (
    SELECT r.r_name, SUM(l.l_extendedprice) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY r.r_name
)
SELECT 
    p.p_name, 
    COALESCE(SUM(ot.total_price), 0) AS total_order_value,
    COALESCE(TR.total_sales, 0) AS region_sales,
    CASE 
        WHEN s_h.level > 0 THEN 'Supplied by multiple levels'
        WHEN s_h.level = 0 THEN 'Single level supplier'
        ELSE 'Supplier not found'
    END AS supplier_level
FROM part p
LEFT JOIN OrderTotals ot ON p.p_partkey = ot.o_orderkey
LEFT JOIN TopRegions TR ON TR.total_sales > 1000
LEFT JOIN SupplierHierarchy s_h ON p.p_partkey = s_h.s_suppkey
GROUP BY p.p_name, s_h.level, TR.total_sales
ORDER BY total_order_value DESC, p.p_name;
