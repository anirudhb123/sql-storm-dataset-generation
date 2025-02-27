SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) as supplier_count,
    MAX(s.s_acctbal) as max_supplier_acctbal,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    SUBSTRING(p.p_comment, 1, 20) AS brief_comment,
    CONCAT('Total Price: $', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 'N2')) AS formatted_total_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    max_supplier_acctbal DESC
LIMIT 10;
