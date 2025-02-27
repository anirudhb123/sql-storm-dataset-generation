WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE sh.level < 3
),
total_lineitem_value AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
)
SELECT 
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    ch.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROUND(AVG(t.total_value), 2) AS avg_order_value,
    SUM(CASE WHEN t.total_value IS NULL THEN 0 ELSE t.total_value END) AS total_order_value
FROM supplier_hierarchy s
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN total_lineitem_value t ON t.l_orderkey = ps.ps_partkey
LEFT JOIN customer_orders o ON o.o_orderkey = t.l_orderkey
LEFT JOIN nation n ON n.n_nationkey = s.s_nationkey
LEFT JOIN (SELECT DISTINCT c.c_custkey, c.c_name FROM customer c WHERE c.c_acctbal IS NOT NULL) ch ON ch.c_custkey = o.o_custkey
WHERE n.r_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'AMERICA')
GROUP BY n.n_name, s.s_name, ch.c_name
ORDER BY total_orders DESC, avg_order_value DESC;
