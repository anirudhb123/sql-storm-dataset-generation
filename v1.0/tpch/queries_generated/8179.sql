WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, CONCAT(sh.s_name, ' -> ', s.s_address), sh.total_supply_cost + COALESCE(SUM(ps.ps_supplycost), 0)
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, sh.total_supply_cost
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(sh.total_supply_cost) AS total_supply_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
GROUP BY r.r_name, n.n_name, s.s_name
ORDER BY total_revenue DESC, total_orders DESC
LIMIT 10;
