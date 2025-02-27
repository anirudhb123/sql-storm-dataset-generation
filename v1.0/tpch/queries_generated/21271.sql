WITH RECURSIVE full_region AS (
    SELECT r_name AS region_name, r_comment, 1 AS level
    FROM region
    UNION ALL
    SELECT CONCAT('Sub-', fr.region_name), CONCAT(fr.r_comment, ' | Nested'), fr.level + 1
    FROM full_region fr 
    WHERE fr.level < 2
),
customer_stats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date,
        MIN(o.o_orderdate) AS first_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
special_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size BETWEEN 1 AND 5 THEN 'Small'
            WHEN p.p_size BETWEEN 6 AND 15 THEN 'Medium'
            ELSE 'Large'
        END AS size_category,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice IS NOT NULL
    GROUP BY p.p_partkey, p.p_name, size_category
),
order_analysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT 
    rf.region_name,
    cs.c_name,
    cs.total_spent,
    p.p_name,
    sa.size_category,
    MAX(oa.net_value) AS max_order_value,
    COUNT(DISTINCT oa.o_orderkey) AS total_orders,
    ARRAY_AGG(DISTINCT s.s_name) FILTER (WHERE s.s_acctbal IS NOT NULL) AS suppliers_with_balance
FROM customer_stats cs
JOIN special_parts p ON cs.total_spent > 1000 AND cs.order_count > 0
LEFT JOIN order_analysis oa ON cs.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey = oa.o_orderkey
    LIMIT 1
)
JOIN region rf ON cs.c_custkey = rf.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany') 
GROUP BY rf.region_name, cs.c_name, p.p_name, sa.size_category
HAVING COUNT(DISTINCT oa.o_orderkey) > 2
ORDER BY max_order_value DESC
