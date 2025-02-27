WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS level
    FROM nation n
    WHERE n.n_name LIKE 'A%'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
    WHERE nh.level < 2
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    cs.order_count,
    cs.avg_order_value,
    ss.total_supply_cost,
    RANK() OVER (PARTITION BY n.n_name ORDER BY ss.total_supply_cost DESC) AS supplier_rank
FROM nation_hierarchy n
LEFT JOIN supplier_stats ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_size BETWEEN 10 AND 100 AND p.p_retailprice < 50.00
    )
)
LEFT JOIN customer_orders cs ON cs.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
)
ORDER BY n.n_name, supplier_rank;
