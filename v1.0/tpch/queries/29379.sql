SELECT 
    CONCAT('Supplier Name: ', s.s_name, ' | Nation: ', n.n_name) AS SupplierInfo,
    SUM(ps.ps_availqty) AS TotalAvailableQuantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS AverageRevenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS PartsSupplied,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_suppkey, s.s_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    TotalAvailableQuantity DESC;