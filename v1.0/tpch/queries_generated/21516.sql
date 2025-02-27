WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rnk
    FROM 
        customer c
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    COALESCE(AVG(s.s_acctbal), 0) AS avg_supp_acctbal,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 
            SUM(l.l_extendedprice * (1 - l.l_discount)) / COUNT(DISTINCT o.o_orderkey) 
        ELSE 
            NULL 
    END AS avg_revenue_per_order
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name IN (SELECT n_name FROM nation WHERE r_regionkey = 2)
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000) 
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 OR (SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL)
ORDER BY 
    total_revenue DESC;

WITH CustomerSegments AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        CASE 
            WHEN c.c_acctbal < 1000 THEN 'Low'
            WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS cust_segment
    FROM 
        customer c
)
SELECT 
    cs.cust_segment,
    COUNT(DISTINCT cs.c_custkey) AS number_of_customers,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders
FROM 
    CustomerSegments cs
LEFT JOIN 
    orders o ON cs.c_custkey = o.o_custkey
GROUP BY 
    cs.cust_segment
HAVING 
    COUNT(DISTINCT o.o_orderkey) >= ALL (SELECT COUNT(DISTINCT o2.o_orderkey) FROM orders o2 GROUP BY o2.o_custkey)
ORDER BY 
    number_of_orders DESC
LIMIT 1;
