SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name, ', Nation: ', n_name) AS SupplierPartDetails,
    SUM(l_quantity) AS TotalQuantity,
    AVG(l_extendedprice * (1 - l_discount)) AS AveragePrice,
    MAX(l_shipdate) AS LatestShipDate,
    COUNT(DISTINCT o_orderkey) AS NumberOfOrders
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
WHERE 
    p.p_comment LIKE '%fragile%'
GROUP BY 
    s.s_suppkey, p.p_partkey, n.n_nationkey
HAVING 
    TotalQuantity > 100
ORDER BY 
    AveragePrice DESC, LatestShipDate DESC;
