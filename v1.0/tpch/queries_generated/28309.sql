SELECT 
    CONCAT_WS(' ', p.p_name, 'from', s.s_name, 'in', n.n_name, 'has', 
               SUM(CASE 
                   WHEN l.l_returnflag = 'R' THEN l.l_quantity * (1 - l.l_discount)
                   ELSE 0 
               END) AS total_returned,
               'at a cost of', 
               SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost,
               'on orders placed',
               COUNT(DISTINCT o.o_orderkey) AS total_orders) AS benchmarking_info
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
    p.p_type LIKE '%metal%' 
    AND o.o_orderdate >= '2022-01-01' 
    AND o.o_orderdate < '2023-01-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_returned DESC;
