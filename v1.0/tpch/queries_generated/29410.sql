SELECT 
    CONCAT('Part Name: ', p.p_name, ' | Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand) AS part_details,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS avg_order_value,
    SUM(l.l_quantity) AS total_quantity_sold,
    MAX(l.l_extendedprice) AS highest_extended_price,
    MIN(l.l_extendedprice) AS lowest_extended_price,
    GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name SEPARATOR ', ') AS regions_available
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 50.00 AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey
ORDER BY 
    total_quantity_sold DESC;
