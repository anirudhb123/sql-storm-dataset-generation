SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(l.l_quantity) AS total_lineitem_quantity,
    AVG(s.s_acctbal) AS average_supplier_balance,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names,
    p.p_comment || ' ' || p.p_type AS part_description
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
    p.p_retailprice > 500.00 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment, p.p_type
ORDER BY 
    total_available_quantity DESC, supplier_count DESC
LIMIT 100;