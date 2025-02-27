SELECT 
    CONCAT(p.p_name, ' ', s.s_name) AS supplier_part_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(s.s_address, ',', 1), ' ', -1) AS city,
    p.p_container, 
    SUM(l.l_quantity) AS total_quantity,
    FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count
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
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND s.s_acctbal > 1000.00
GROUP BY 
    supplier_part_name, city, p.p_container
HAVING 
    total_quantity > 500
ORDER BY 
    total_revenue DESC, order_count ASC
LIMIT 10;
