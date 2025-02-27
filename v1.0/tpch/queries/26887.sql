SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS Returned_Quantity,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS Avg_Net_Price,
    r.r_name AS Region_Name,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS Market_Segments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%steel%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name
ORDER BY 
    Total_Orders DESC, Returned_Quantity ASC;