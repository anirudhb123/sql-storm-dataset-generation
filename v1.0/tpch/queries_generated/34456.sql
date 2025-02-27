WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
order_totals AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(ot.total_price) AS total_spent
    FROM customer c
    JOIN order_totals ot ON c.c_custkey = ot.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
),
supplier_parts AS (
    SELECT ps.ps_partkey, s.s_name, p.p_mfgr, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty IS NOT NULL AND ps.ps_supplycost IS NOT NULL
)
SELECT 
    p.p_name,
    sp.s_name AS supplier_name,
    sp.ps_availqty,
    SUM(CASE WHEN ot.total_price IS NOT NULL THEN ot.total_price ELSE 0 END) AS total_sales,
    RANK() OVER (PARTITION BY sp.s_name ORDER BY SUM(CASE WHEN ot.total_price IS NOT NULL THEN ot.total_price ELSE 0 END) DESC) AS sales_rank
FROM 
    part p
LEFT JOIN supplier_parts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN order_totals ot ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o))
GROUP BY 
    p.p_name, sp.s_name, sp.ps_availqty
HAVING 
    AVG(sp.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM supplier_parts) AND 
    COUNT(ot.o_orderkey) >= 1
ORDER BY 
    total_sales DESC, p.p_name;
