WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_retailprice, 
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
order_summary AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM orders o
    GROUP BY o.o_custkey
),
customer_rank AS (
    SELECT 
        c.c_custkey, 
        DENSE_RANK() OVER (ORDER BY o.total_order_value DESC) AS customer_rank
    FROM customer c
    JOIN order_summary o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name, 
    ns.n_name,
    ps.p_partkey AS part_key,
    ps.total_supplycost,
    cr.customer_rank,
    MAX(CASE WHEN pp.price_rank = 1 THEN pp.p_name END) AS highest_priced_part,
    COUNT(DISTINCT cr.c_custkey) AS high_value_customers
FROM ranked_parts pp
FULL OUTER JOIN supplier_stats ps ON pp.p_partkey = ps.s_suppkey
JOIN nation ns ON ns.n_nationkey = ps.s_suppkey
JOIN region r ON r.r_regionkey = ns.n_regionkey
JOIN customer_rank cr ON cr.customer_rank = 1
WHERE ps.total_supplycost IS NOT NULL 
  AND pp.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
GROUP BY r.r_name, ns.n_name, ps.p_partkey, ps.total_supplycost, cr.customer_rank
HAVING COUNT(DISTINCT cr.c_custkey) OVER (PARTITION BY r.r_name) > 2
ORDER BY ns.n_name ASC, ps.total_supplycost DESC;
