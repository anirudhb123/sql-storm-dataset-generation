WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey IN (
        SELECT p_partkey 
        FROM part 
        WHERE p_retailprice < (SELECT AVG(p_retailprice) FROM part WHERE p_size IS NOT NULL)
    )
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    r.r_name AS Region, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    AVG(DATEDIFF(l.l_shipdate, o.o_orderdate)) AS Avg_Shipping_Time,
    MAX(s.s_acctbal) AS Max_Supplier_Balance,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS Activity_Status,
    COALESCE(NULLIF(s.s_name, ''), 'Unknown Supplier') AS Supplier_Name
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN 
    supplier s ON sh.s_suppkey = s.s_suppkey
WHERE 
    l.l_shipdate BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND CURDATE()
    AND (l.l_discount BETWEEN 0.05 AND 0.15 OR l.l_discount IS NULL)
GROUP BY 
    r.r_name
HAVING 
    Revenue > (SELECT AVG(Revenue) FROM (
                  SELECT 
                      SUM(l_extendedprice * (1 - l_discount)) AS Revenue
                  FROM 
                      lineitem 
                  GROUP BY 
                      l_orderkey
                ) AS T)
ORDER BY 
    Revenue DESC
LIMIT 10;
