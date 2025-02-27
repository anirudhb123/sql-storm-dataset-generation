SELECT 
    n.n_name AS nation_name,
    p.p_name AS part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS supplier_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    n.n_name LIKE 'A%' AND
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    n.n_name, p.p_name
ORDER BY 
    total_revenue DESC, supplier_count DESC;