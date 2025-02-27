SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(CASE 
            WHEN LENGTH(s.s_name) > 10 THEN 'Long Supplier Name' 
            ELSE 'Short Supplier Name' 
        END) AS name_length_category,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_totalprice) AS max_order_price,
    MIN(o.o_orderdate) AS earliest_order_date,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 30 AND 
    s.s_acctbal > 1000
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    total_available_quantity DESC;
