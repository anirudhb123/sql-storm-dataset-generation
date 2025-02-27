SELECT 
    CONCAT('Part: ', p_name, ' | Manufacturer: ', p_mfgr, ' | Region: ', r_name, 
           ' | Supplier: ', s_name, ' | Customer: ', c_name, 
           ' | Order Date: ', CAST(o_orderdate AS CHAR), 
           ' | Total Price: $', FORMAT(o_totalprice, 2)) AS benchmark_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p_name LIKE '%widget%'
    AND o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
ORDER BY 
    o_orderdate DESC
LIMIT 100;
