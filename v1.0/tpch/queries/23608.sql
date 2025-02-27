
WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IS NOT NULL
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
    WHERE nh.level < 2
),
average_prices AS (
    SELECT p.p_partkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
supplier_stats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
order_details AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
customer_order_count AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
ranked_customers AS (
    SELECT coc.c_custkey, coc.order_count, RANK() OVER (ORDER BY coc.order_count DESC) AS rank
    FROM customer_order_count coc
)
SELECT 
    r.n_name AS nation_name,
    COALESCE(ap.avg_price, 0) AS average_price,
    ss.total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT lc.l_linenumber) AS total_lineitems,
    MAX(CASE WHEN rc.rank <= 10 THEN c.c_name ELSE NULL END) AS top_customer
FROM nation_hierarchy r
LEFT JOIN average_prices ap ON r.n_nationkey = ap.p_partkey
LEFT JOIN supplier_stats ss ON r.n_nationkey = ss.s_suppkey
LEFT JOIN orders o ON o.o_orderkey IN (SELECT o_orderkey FROM order_details)
LEFT JOIN lineitem lc ON o.o_orderkey = lc.l_orderkey
LEFT JOIN ranked_customers rc ON lc.l_orderkey = rc.c_custkey
LEFT JOIN customer c ON rc.c_custkey = c.c_custkey
WHERE r.n_regionkey IS NOT NULL
GROUP BY r.n_name, ap.avg_price, ss.total_supply_cost
HAVING SUM(lc.l_quantity) > (SELECT AVG(l_quantity) FROM lineitem WHERE l_shipdate >= CURRENT_DATE - INTERVAL '30 DAY')
ORDER BY r.n_name;
