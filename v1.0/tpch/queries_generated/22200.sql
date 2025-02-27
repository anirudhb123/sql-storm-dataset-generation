WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name IN ('FRANCE', 'GERMANY'))
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
),
ranked_part AS (
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
customer_region AS (
    SELECT c.c_custkey, c.c_name, r.r_name
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT cr.r_name, 
       JSON_AGG(JSON_BUILD_OBJECT('cust_name', cr.c_name, 'order_key', os.o_orderkey, 'total_value', os.total_value,
                                   'part_details', (
                                       SELECT JSON_AGG(JSON_BUILD_OBJECT('part_name', rp.p_name, 'price', rp.p_retailprice))
                                       FROM ranked_part rp
                                       WHERE rp.price_rank <= 3 AND rp.p_size < (CASE WHEN os.line_count > 10 THEN 50 ELSE 30 END)
                                   )))
       ) AS customer_orders
FROM customer_region cr
LEFT JOIN order_summary os ON cr.c_custkey = os.o_orderkey
WHERE cr.r_name IS NOT NULL
GROUP BY cr.r_name
HAVING COUNT(os.o_orderkey) > 5
ORDER BY cr.r_name;
