WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE oh.depth < 5
),
supplier_avg_cost AS (
    SELECT ps.s_suppkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.s_suppkey
),
custom_lines AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS rn
    FROM lineitem l
    WHERE l.l_discount > 0.05
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, n.n_name, 
       c.c_name, cs.total_spent, 
       (SELECT COUNT(DISTINCT s.s_suppkey) 
        FROM supplier s 
        LEFT JOIN supplier_avg_cost sac ON s.s_suppkey = sac.s_suppkey 
        WHERE sac.avg_supply_cost < 100) AS low_cost_suppliers,
       OL.depth,
       ARRAY_AGG(DISTINCT CASE WHEN cl.l_orderkey IS NOT NULL THEN cl.l_quantity ELSE NULL END) AS quantities
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN customer_summary cs ON s.s_suppkey = cs.c_custkey
LEFT JOIN order_hierarchy OL ON cs.c_custkey = OL.o_custkey
LEFT JOIN custom_lines cl ON OL.o_orderkey = cl.l_orderkey
WHERE cs.total_spent > 1000
GROUP BY r.r_name, n.n_name, c.c_name, cs.total_spent, OL.depth
ORDER BY total_spent DESC, OL.depth;
