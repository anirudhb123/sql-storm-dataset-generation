
SELECT 
    p.p_name, 
    p.p_brand, 
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    p.p_mfgr LIKE 'Manufacturer%'
    AND n.n_name IN (SELECT r_name FROM region WHERE r_comment LIKE '%quality%')
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, s.s_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 500
ORDER BY 
    AVG(l.l_extendedprice) DESC, COUNT(DISTINCT c.c_custkey) ASC
LIMIT 10;
