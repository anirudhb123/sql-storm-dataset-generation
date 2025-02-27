
SELECT 
    p.p_name, 
    CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name, ' | Region: ', r.r_name, ' | Price: ', CAST(p.p_retailprice AS DECIMAL(10, 2))) AS SupplierInfo,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity 
            ELSE 0 
        END) AS TotalReturnedQuantity,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    STRING_AGG(DISTINCT CONCAT('OrderID: ', o.o_orderkey, ' | Status: ', o.o_orderstatus), '; ') AS OrderDetails
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 AND 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name, r.r_name, p.p_retailprice
ORDER BY 
    TotalReturnedQuantity DESC, TotalOrders DESC;
