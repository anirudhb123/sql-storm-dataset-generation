SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS average_account_balance,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    MAX(o.o_totalprice) AS max_order_price
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
    p.p_retailprice > 100.00
    AND s.s_acctbal < 5000.00
GROUP BY 
    short_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    average_account_balance DESC;
