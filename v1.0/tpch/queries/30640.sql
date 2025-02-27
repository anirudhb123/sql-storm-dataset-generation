
WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_size, 0 AS level
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON p.p_partkey = ph.p_partkey
    WHERE p.p_size <= 10
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
ranked_suppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.total_parts,
        ss.total_supplycost,
        RANK() OVER (ORDER BY ss.total_supplycost DESC) AS supplycost_rank
    FROM supplier_summary ss
    WHERE ss.total_parts > 5
)
SELECT 
    ch.p_name,
    ch.level,
    cs.total_orders,
    cs.total_spent,
    rs.supplycost_rank,
    COALESCE(rs.total_supplycost, 0) AS supply_cost_or_zero
FROM part_hierarchy ch
LEFT JOIN customer_order_summary cs ON ch.p_size = cs.c_custkey
LEFT JOIN ranked_suppliers rs ON rs.s_suppkey = ch.p_partkey
WHERE 
    ch.level < 2 AND 
    (cs.total_orders IS NULL OR cs.total_spent > 1000)
ORDER BY ch.p_name;
