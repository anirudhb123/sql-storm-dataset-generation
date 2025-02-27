SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS unique_ship_modes
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE 'PROMO%'
    AND o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1997-10-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, avg_extended_price ASC;