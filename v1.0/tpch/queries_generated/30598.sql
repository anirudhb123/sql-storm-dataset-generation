WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS depth 
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    n.n_name AS nation,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_net_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT p.p_name, '; ') AS products_supplied,
    COALESCE(MAX(o.o_orderdate), 'No orders') AS last_order_date,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returned_orders,
    COUNT(DISTINCT s.s_name) AS number_of_suppliers,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
FROM order o
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
AND l.l_shipdate IS NOT NULL
GROUP BY n.n_name
HAVING SUM(o.o_totalprice) > 100000
ORDER BY total_revenue DESC;
