SELECT 
    s.s_suppkey AS SupplierKey,
    s.s_name AS SupplierName,
    CONCAT(r.r_name, ' - ', n.n_name) AS RegionNation,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS TotalReturnedQuantity,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS AverageRevenuePerOrder,
    STRING_AGG(DISTINCT p.p_name, ', ') AS DistinctPartNames
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_suppkey, s.s_name, r.r_name, n.n_name
ORDER BY 
    TotalOrders DESC, TotalReturnedQuantity ASC;