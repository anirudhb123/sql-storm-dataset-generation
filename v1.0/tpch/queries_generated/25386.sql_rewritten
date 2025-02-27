SELECT 
    SUBSTRING(p.p_name, 1, 20) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS avg_supplier_account_balance,
    r.r_name AS region_name,
    LEFT(n.n_name, 10) AS short_nation_name,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_name LIKE '%widget%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    short_name, region_name, short_nation_name
ORDER BY 
    total_available_quantity DESC, region_name ASC;