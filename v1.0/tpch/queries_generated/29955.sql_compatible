
SELECT 
    n.n_name AS Nation, 
    COUNT(DISTINCT s.s_suppkey) AS SupplierCount, 
    SUM(CASE WHEN p.p_size > 10 THEN ps.ps_availqty ELSE 0 END) AS TotalAvailableQtyOver10,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost, 
    STRING_AGG(DISTINCT p.p_name, ', ') AS PartNames
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_name LIKE '%land%'
GROUP BY 
    n.n_name
HAVING 
    SUM(CASE WHEN p.p_size > 10 THEN ps.ps_availqty ELSE 0 END) > 1000
ORDER BY 
    SupplierCount DESC, TotalSupplyCost ASC;
