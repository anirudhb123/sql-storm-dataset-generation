SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_acctbal, ')'), '; ') AS Customer_Details,
    r.r_name AS Region,
    n.n_name AS Nation,
    p.p_comment AS Part_Comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1998-01-01'
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    Total_Revenue DESC;