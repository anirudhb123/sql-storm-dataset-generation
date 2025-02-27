WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS Level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.Level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)
SELECT 
    p.p_name,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    AVG(CASE WHEN c.c_acctbal IS NOT NULL THEN c.c_acctbal ELSE 0 END) AS AvgCustomerBalance,
    r.r_name AS Region,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice) DESC) AS Rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (l.l_returnflag = 'N'
         OR EXISTS (SELECT 1 FROM OrderHierarchy oh WHERE oh.o_orderkey = o.o_orderkey AND oh.Level <= 2))
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) > 1000
ORDER BY 
    r.r_name, TotalRevenue DESC;
