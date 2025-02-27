WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_availability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    cs.c_custkey,
    cs.total_spent,
    cs.order_count,
    sh.level AS supplier_level
FROM part_availability ps
JOIN customer_summary cs ON ps.total_avail_qty > cs.order_count
LEFT JOIN supplier_hierarchy sh ON cs.order_count = sh.level
WHERE ps.total_avail_qty IS NOT NULL
ORDER BY ps.p_partkey, sh.level DESC
LIMIT 50;
