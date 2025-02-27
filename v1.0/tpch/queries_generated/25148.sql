SELECT 
    substr(p.p_name, 1, 10) AS short_name,
    length(p.p_name) AS name_length,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    count(DISTINCT o.o_orderkey) AS order_count,
    sum(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    trim(upper(s.s_comments)) AS trimmed_supplier_comment
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
WHERE 
    p.p_name LIKE '%widget%'
    AND n.n_name IS NOT NULL
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    short_name, name_length, nation_name, supplier_name
ORDER BY 
    total_revenue DESC, name_length ASC;
