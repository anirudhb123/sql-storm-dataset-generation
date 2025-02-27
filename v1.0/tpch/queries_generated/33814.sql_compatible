
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS average_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count,
    RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01'
AND 
    l.l_shipdate < DATE '1998-01-01'
AND 
    (c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000)
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    total_revenue DESC;
