
SELECT 
    p.p_name,
    SUBSTR(p.p_comment, 1, 10) AS short_comment,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_account_balance
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
WHERE 
    p.p_type LIKE '%metal%'
    AND p.p_retailprice > 20.00
GROUP BY 
    p.p_name, 
    SUBSTR(p.p_comment, 1, 10),
    r.r_name, 
    n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    AVG(s.s_acctbal) DESC
LIMIT 10;
