SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name, 
    COUNT(DISTINCT ps_partkey) AS part_count, 
    AVG(s_acctbal) AS avg_supplier_balance,
    MAX(o_totalprice) AS max_order_value,
    STRING_AGG(DISTINCT r_name, ', ') AS regions_supplied
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
WHERE 
    p.p_retailprice > 50.00 AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    short_name
ORDER BY 
    avg_supplier_balance DESC, 
    part_count DESC;