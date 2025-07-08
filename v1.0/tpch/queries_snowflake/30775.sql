WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
regional_sales AS (
    SELECT n.n_name, r.r_name, SUM(os.total_revenue) AS total_sales
    FROM order_summary os
    JOIN customer c ON os.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name, ' - Total Sales: ', COALESCE(rs.total_sales, 0)) AS sales_report
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN regional_sales rs ON n.n_name = rs.n_name AND r.r_name = rs.r_name
WHERE r.r_name IS NOT NULL
ORDER BY r.r_name, n.n_name;
