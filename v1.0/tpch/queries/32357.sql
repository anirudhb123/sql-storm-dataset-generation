
WITH RECURSIVE supplier_sales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
region_summary AS (
    SELECT n.n_regionkey, r.r_name, SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT 
    rs.r_name,
    COALESCE(cs.order_count, 0) AS total_orders,
    COALESCE(cs.avg_order_value, 0) AS average_order_value,
    SUM(ss.total_sales) AS supplier_sales,
    COUNT(DISTINCT ss.s_suppkey) AS distinct_suppliers
FROM region_summary rs
LEFT JOIN customer_orders cs ON rs.r_name LIKE '%' || cs.c_name || '%'
LEFT JOIN supplier_sales ss ON rs.r_name IN (
    SELECT r.r_name 
    FROM nation n 
    JOIN region r ON n.n_regionkey = r.r_regionkey 
    WHERE n.n_nationkey IN (
        SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ss.s_suppkey
    )
)
GROUP BY rs.r_name, cs.order_count, cs.avg_order_value
HAVING SUM(ss.total_sales) > 10000
ORDER BY supplier_sales DESC, total_orders DESC;
