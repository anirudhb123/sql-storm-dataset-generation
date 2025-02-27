SELECT 
    CONCAT(s.s_name, ' from ', r.r_name) AS SupplierRegion,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS PartNames,
    SUM(ps.ps_availqty) AS TotalAvailableQuantity
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
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1998-01-01'
    AND s.s_acctbal > 5000
GROUP BY 
    SupplierRegion
ORDER BY 
    TotalRevenue DESC;