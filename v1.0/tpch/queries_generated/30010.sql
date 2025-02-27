WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT n.n_name, ', ') AS supplier_nations,
    CASE 
        WHEN SUM(l.l_extendedprice) > 10000 THEN 'High'
        WHEN SUM(l.l_extendedprice) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS rank

FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= DATE '2023-01-01'
    AND l.l_shipdate <= DATE '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(o.o_orderkey) > 10 OR SUM(l.l_extendedprice) IS NULL
ORDER BY 
    total_revenue DESC
LIMIT 100;


