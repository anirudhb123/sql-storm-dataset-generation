SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, ' listed with a price of ', FORMAT(p.p_retailprice, 2)) AS descriptive_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    p.p_name LIKE '%BRASS%' 
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name IN ('GERMANY', 'FRANCE'))
    AND o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_revenue DESC, part_name ASC;
