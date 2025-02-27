WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey
),
customer_revenue AS (
    SELECT c.c_custkey, c.c_name, COALESCE(os.total_revenue, 0) AS total_revenue
    FROM customer c
    LEFT JOIN order_summary os ON c.c_custkey = os.o_custkey
),
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, c.total_revenue,
           RANK() OVER (ORDER BY c.total_revenue DESC) AS revenue_rank
    FROM customer_revenue c
)
SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Volume'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON p.p_partkey = l.l_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    ranked_customers rc ON rc.c_custkey = s.s_nationkey
WHERE 
    (p.p_size > 10 OR p.p_type LIKE '%metal%')
    AND s.s_acctbal IS NOT NULL
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity) > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_orderkey IN 
                         (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'F'))
ORDER BY 
    total_quantity DESC;
