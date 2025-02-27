SELECT 
    CONCAT('Part Name: ', p.p_name, ', Manufacturer: ', p.p_mfgr) AS part_details,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    STRING_AGG(DISTINCT concat('Order Date: ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD'), ', Status: ', o.o_orderstatus), '; ') AS order_summary
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
WHERE 
    p.p_retailprice > 50.00
    AND l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    p.p_partkey, s.s_name, c.c_name, o.o_orderkey
ORDER BY 
    total_quantity DESC, part_details;
