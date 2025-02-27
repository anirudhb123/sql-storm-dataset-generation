WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_suppkey IN (
        SELECT ps_suppkey
        FROM partsupp
        WHERE ps_availqty > 100
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        COUNT(l.l_linenumber) AS line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
customer_preferences AS (
    SELECT c.c_custkey, c.c_mktsegment, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 5000 AND c.c_mktsegment IN ('BUILDING', 'INDUSTRY')
    GROUP BY c.c_custkey, c.c_mktsegment
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    SUM(ps.ps_availqty) AS total_available,
    sh.level,
    cs.c_mktsegment,
    coalesce(avg(cs.avg_order_value), 0) AS average_customer_order_value,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN order_summary o ON o.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = p.p_partkey
)
LEFT JOIN customer_preferences cs ON cs.c_custkey = o.o_custkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice)
    FROM part p2
    WHERE p2.p_type = p.p_type
)
GROUP BY p.p_name, p.p_brand, p.p_type, sh.level, cs.c_mktsegment
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_available DESC, average_customer_order_value DESC;
