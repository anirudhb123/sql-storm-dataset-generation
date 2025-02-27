
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE ps.ps_availqty > 100
),
total_sales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey
),
region_sales AS (
    SELECT n.n_name, r.r_name, SUM(ts.total_sales_amount) AS region_total
    FROM total_sales ts
    JOIN customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ts.o_orderkey)
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT r.r_name, n.n_name, COALESCE(rs.region_total, 0) AS total_sales
FROM region r
LEFT JOIN region_sales rs ON r.r_name = rs.r_name
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
ORDER BY total_sales DESC
LIMIT 10;
