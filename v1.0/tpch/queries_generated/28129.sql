SELECT 
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(CASE WHEN LENGTH(p.p_name) > 20 THEN 1 ELSE 0 END) AS long_part_names,
    AVG(LENGTH(p.p_comment)) AS avg_comment_length,
    r.r_name AS region_name,
    CONCAT(n.n_name, ' (', n.n_nationkey, ')') AS nation_info,
    SUM(s.s_acctbal) as total_supplier_balance,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT CONCAT(o.o_orderpriority, ': ', o.o_comment), '; ') AS order_priorities_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50.00
GROUP BY 
    r.r_name, n.n_name, n.n_nationkey
ORDER BY 
    unique_parts DESC, total_supplier_balance DESC;
