WITH RECURSIVE PriceDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        1 AS Level
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
    
    UNION ALL

    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice * 0.9 AS DiscountedPrice,
        CONCAT(pd.p_comment, ' - Discounted at level ', pd.Level + 1) AS p_comment,
        pd.Level + 1
    FROM 
        PriceDetails pd
    JOIN 
        part p ON pd.Level < 5 AND p.p_partkey <> pd.p_partkey
)

SELECT 
    COUNT(DISTINCT c.c_custkey) AS Total_Customers,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS Total_Revenue,
    AVG(l.l_quantity) AS Average_Quantity,
    r.r_name AS Region_Name,
    MAX(ps.ps_supplycost) AS Max_Supply_Cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY Total_Revenue DESC) AS Revenue_Rank
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    r.r_regionkey,
    r.r_name
HAVING 
    SUM(l.l_extendedprice * l.l_discount) > 1000
ORDER BY 
    Total_Revenue DESC
LIMIT 10;
