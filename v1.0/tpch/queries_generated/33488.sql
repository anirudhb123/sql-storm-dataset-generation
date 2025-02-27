WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 20 AND sh.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
order_line_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    co.total_spent AS customer_spending,
    SUM(COALESCE(ols.total_line_price, 0)) AS total_order_value,
    CASE 
        WHEN COUNT(DISTINCT ols.o_orderkey) > 10 THEN 'High Volume' 
        ELSE 'Low Volume' 
    END AS order_volume_category
FROM supplier_hierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer_orders co ON co.c_custkey = s.s_nationkey
LEFT JOIN order_line_summary ols ON ols.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = co.c_custkey
)
WHERE r.r_name IS NOT NULL
GROUP BY s.s_name, r.r_name, co.total_spent
HAVING SUM(co.total_spent) IS NOT NULL AND SUM(ols.total_line_price) IS NOT NULL
ORDER BY total_order_value DESC, customer_spending DESC
LIMIT 10;
