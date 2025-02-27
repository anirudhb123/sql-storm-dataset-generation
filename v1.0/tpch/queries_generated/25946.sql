SELECT 
    p.p_name,
    CONCAT(p.p_mfgr, ' - ', p.p_type) AS manufacturer_and_type,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUM(l.l_extendedprice - l.l_discount) AS total_sales
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'S%'
    AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    p.p_name, p.p_mfgr, p.p_type
HAVING 
    total_sales > 10000
ORDER BY 
    total_sales DESC;
