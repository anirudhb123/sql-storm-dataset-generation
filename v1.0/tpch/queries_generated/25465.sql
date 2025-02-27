SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    r.r_name AS region_name,
    CONCAT('Total Price: ', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS total_revenue
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
    lineitem l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_name, r.r_name, p.p_comment
HAVING 
    total_available_quantity > 100
ORDER BY 
    average_supplier_account_balance DESC, p.p_name ASC;
