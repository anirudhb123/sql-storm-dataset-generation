SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name) AS Supplier_Part_Info,
    COUNT(DISTINCT o_orderkey) AS Total_Orders,
    SUM(l_extendedprice * (1 - l_discount)) AS Total_Sales,
    STRING_AGG(DISTINCT r_name, ', ') AS Regions_Served
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND s.s_acctbal > 10000 
    AND p.p_retailprice < 50
GROUP BY 
    s_name, p_name
ORDER BY 
    Total_Sales DESC;