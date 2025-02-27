WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supply_chain sc ON sc.ps_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > sc.ps_availqty
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
region_stats AS (
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    rs.order_rank,
    rs.o_totalprice AS order_value,
    rs.o_orderkey,
    rg.r_name AS region_name,
    rg.total_revenue,
    CASE WHEN ss.ps_availqty IS NULL THEN 'Out of Stock' ELSE 'In Stock' END AS stock_status
FROM customer_summary cs
LEFT JOIN ranked_orders rs ON cs.total_orders > 0
JOIN supply_chain ss ON ss.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 50 LIMIT 1)
JOIN region_stats rg ON rg.total_revenue > 100000
WHERE 
    cs.c_name LIKE '%ABC%' 
    OR rg.r_name LIKE '%North%'
ORDER BY rg.total_revenue DESC, cs.c_name;
