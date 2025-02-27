
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        NULL AS parent_suppkey
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.s_suppkey
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
)

SELECT 
    n.n_name AS nation,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice 
        ELSE NULL 
    END) AS avg_returned_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) DESC) AS rank
FROM 
    nation n
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND DATE '1998-10-01'
GROUP BY 
    n.n_name
HAVING 
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) > 50000
ORDER BY 
    total_revenue DESC;
