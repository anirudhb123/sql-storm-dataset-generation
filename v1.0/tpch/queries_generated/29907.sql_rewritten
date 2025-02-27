SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS Supplier_Info,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_quantity) AS Total_Quantity,
    AVG(l.l_extendedprice - l.l_discount) AS Average_Profit,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS Shipping_Modes
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name IN ('Germany', 'USA') 
    AND p.p_type LIKE '%metal%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    Total_Quantity DESC, Average_Profit DESC;