
WITH RECURSIVE supplier_tree AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_suppkey IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, st.level + 1
    FROM supplier s
    JOIN supplier_tree st ON s.s_nationkey = st.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(c.c_acctbal) AS avg_customer_balance,
    LISTAGG(DISTINCT p.p_name, ', ') AS product_names,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS region_ranking
FROM 
    region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE '%East%'
    AND (p.p_retailprice > 20.00 OR p.p_size > 5)
    AND c.c_acctbal IS NOT NULL
GROUP BY 
    r.r_regionkey, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;
