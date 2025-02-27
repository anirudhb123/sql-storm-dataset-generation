WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_REPLACE(p.p_name, '[^a-zA-Z0-9]', '') AS clean_name,
        CONCAT(SUBSTRING(p.p_name, 1, 5), '...', SUBSTRING(p.p_name, -5)) AS truncated_name
    FROM part p
),
supplier_stats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    pp.p_partkey,
    pp.clean_name,
    ss.s_name,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    pp.comment_length,
    pp.truncated_name
FROM processed_parts pp
JOIN supplier_stats ss ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
JOIN customer_order_summary cs ON cs.total_orders > 10
WHERE pp.comment_length > 10
ORDER BY pp.p_partkey, ss.total_supply_cost DESC, cs.total_spent DESC;
