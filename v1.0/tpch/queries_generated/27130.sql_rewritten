SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    concat('Supplier ', s.s_name, ' of part ', p.p_name) AS descriptive_info,
    r.r_name AS region_name,
    count(distinct c.c_custkey) AS customer_count,
    sum(l.l_quantity) AS total_quantity,
    avg(l.l_discount) AS average_discount,
    string_agg(distinct n.n_name, ', ') AS nationality_list
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
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name
ORDER BY 
    total_quantity DESC, average_discount ASC;