WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
customer_order_summary AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        ROW_NUMBER() OVER (PARTITION BY co.total_orders ORDER BY co.total_spent DESC) AS ranking
    FROM customer_orders co
    WHERE co.total_spent IS NOT NULL
),
part_supplier_stats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 20.00
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ch.c_name AS customer_name,
    ch.total_orders,
    ch.total_spent,
    ph.p_name AS part_name,
    ps.total_available_qty,
    ps.avg_supply_cost,
    ROW_NUMBER() OVER (ORDER BY ch.total_spent DESC) AS customer_rank,
    COALESCE(sh.level, -1) AS supplier_level
FROM customer_order_summary ch
LEFT JOIN part_supplier_stats ps ON ps.total_available_qty > 50
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = ch.c_custkey
LEFT JOIN LATERAL (
    SELECT p.p_name 
    FROM part p 
    WHERE p.p_size = (SELECT MAX(p_size) FROM part)
    LIMIT 1
) ph ON TRUE
WHERE ch.ranking <= 10
ORDER BY customer_rank;
