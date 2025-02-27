SELECT 
    CONCAT(s.s_name, ' ', p.p_name) AS SupplierPart,
    SUBSTRING(p.p_type, 1, 10) AS ShortType,
    LENGTH(p.p_comment) AS CommentLength,
    REPLACE(p.p_comment, 'Fragile', '') AS CleanedComment,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(l.l_quantity) AS TotalQuantity,
    AVG(p.p_retailprice) AS AveragePrice
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
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    SupplierPart, ShortType, CommentLength, CleanedComment
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 AND 
    AVG(p.p_retailprice) < 100.00
ORDER BY 
    AveragePrice DESC;
