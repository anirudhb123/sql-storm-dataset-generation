WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_clerk,
        0 AS Level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'P'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_clerk,
        Level + 1
    FROM 
        orders o
    INNER JOIN OrderHierarchy oh ON oh.o_orderkey = o.o_orderkey
)
SELECT 
    n.n_name AS Nation,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    SUM(o.o_totalprice) AS TotalSales,
    AVG(o.o_totalprice) AS AverageSales,
    ROUND(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END), 2) AS TotalReturned,
    MAX(ps.ps_supplycost) AS MaxSupplyCost,
    (SELECT AVG(s.s_acctbal) 
     FROM supplier s 
     WHERE s.s_nationkey = n.n_nationkey) AS AverageSupplierBalance
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey 
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = l.l_partkey
WHERE 
    o.o_orderdate >= DATE '2023-01-01' 
    AND o.o_orderdate < DATE '2024-01-01'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    TotalSales DESC
LIMIT 10;
