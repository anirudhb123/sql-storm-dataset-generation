WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT n_nationkey FROM supplier)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
)
SELECT 
    r.r_name AS Region_Name,
    COUNT(DISTINCT c.c_custkey) AS Unique_Customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    AVG(s.s_acctbal) AS Average_Supplier_Balance,
    STRING_AGG(DISTINCT p.p_name, ', ') AS Product_Names,
    DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Revenue_Rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderstatus = 'F' 
    AND l.l_shipdate >= '2023-01-01' 
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    Total_Revenue DESC;
