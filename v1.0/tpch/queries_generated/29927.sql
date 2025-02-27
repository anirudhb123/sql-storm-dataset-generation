SELECT 
    CONCAT('Supplier ', s.s_name, ' from Nation ', n.n_name, 
           ' provides ', p.p_name, ', a ', p.p_container, 
           ' of size ', p.p_size, ' priced at $', 
           FORMAT(p.p_retailprice, 2), ' with comment: ', p.p_comment) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.r_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Asia%')
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY 
    s.s_suppkey, n.n_name, p.p_partkey
ORDER BY 
    total_sales DESC;
