WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2
            WHERE s2.s_nationkey = s.s_nationkey
        )
    UNION ALL
    SELECT
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        sh.level + 1
    FROM 
        SupplierHierarchy sh
    JOIN 
        partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
)

SELECT DISTINCT 
    n.n_name AS Nation, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE NULL END) AS ReturnedSales,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    AVG(sh.level) AS AvgSupplierLevel,
    CONCAT(n.n_name, ' - ', CASE WHEN SUM(l.l_extendedprice) IS NOT NULL THEN 'Has Sales' ELSE 'No Sales' END) AS SalesStatus
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 OR AVG(sh.level) > 2
ORDER BY 
    ReturnedSales DESC NULLS LAST;
