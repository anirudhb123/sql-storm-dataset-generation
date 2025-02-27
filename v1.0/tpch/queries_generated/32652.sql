WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 
           NULL::integer AS parent_suppkey
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT p.s_suppkey, p.s_name, p.s_acctbal,
           sh.s_suppkey AS parent_suppkey
    FROM supplier p
    JOIN SupplierHierarchy sh ON p.s_nationkey = sh.s_nationkey
)

SELECT 
    r.r_name AS Region, 
    n.n_name AS Nation, 
    s.s_name AS Supplier, 
    SUM(ps.ps_supplycost * l.l_quantity) AS TotalCost,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    AVG(s.s_acctbal) OVER (PARTITION BY n.n_name) AS AvgSupplierBalance,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_size, ')'), ', ') AS PartNames
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    l.l_shipdate >= '2023-01-01' AND 
    l.l_shipdate < '2023-12-31' AND
    (l.l_discount > 0.05 OR l.l_tax > 0.07)
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    TotalCost DESC
LIMIT 10;

