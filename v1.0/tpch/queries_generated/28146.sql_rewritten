SELECT 
    n.n_name AS Nation, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    COUNT(DISTINCT c.c_custkey) AS TotalCustomers,
    AVG(s.s_acctbal) AS AverageSupplierBalance,
    STRING_AGG(DISTINCT p.p_name, ', ') AS ProductList
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1998-01-01'
    AND l.l_returnflag = 'N'
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY 
    TotalRevenue DESC;