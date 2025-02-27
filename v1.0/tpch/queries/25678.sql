SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    MAX(l.l_extendedprice) AS max_extended_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    SUBSTRING(r.r_name FROM 1 FOR 10) AS short_region_name
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
    p.p_comment LIKE '%fragile%'
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1998-01-01'
GROUP BY 
    p.p_name, short_region_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_available_quantity DESC, unique_suppliers ASC;