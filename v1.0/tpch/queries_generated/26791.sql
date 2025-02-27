SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUBSTRING_INDEX(c.c_address, ' ', 1) AS address_first_word,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date,
    GROUP_CONCAT(DISTINCT CONCAT(p.p_type, ' (', p.p_brand, ')') ORDER BY p.p_type ASC SEPARATOR ', ') AS part_types,
    CASE 
        WHEN SUM(l.l_quantity) > 1000 THEN 'High Volume'
        WHEN SUM(l.l_quantity) BETWEEN 500 AND 1000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
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
    p.p_retailprice > 50.00 AND
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey, r.r_regionkey
HAVING 
    total_orders > 0
ORDER BY 
    total_revenue DESC, part_name;
