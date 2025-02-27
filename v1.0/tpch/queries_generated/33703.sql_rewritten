WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)

SELECT 
    n.n_name AS Nation,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    SUM(o.o_totalprice) AS TotalRevenue,
    AVG(o.o_totalprice) AS AverageOrderValue,
    MAX(o.o_totalprice) AS MaxOrderValue,
    CASE 
        WHEN AVG(o.o_totalprice) > 1000 THEN 'High Value'
        WHEN AVG(o.o_totalprice) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS OrderValueCategory,
    STRING_AGG(DISTINCT p.p_name, ', ') AS ProductNames
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND (l.l_discount > 0.05 OR l.l_discount IS NULL)
GROUP BY 
    n.n_name
HAVING 
    SUM(o.o_totalprice) > 10000
ORDER BY 
    TotalRevenue DESC
LIMIT 10;