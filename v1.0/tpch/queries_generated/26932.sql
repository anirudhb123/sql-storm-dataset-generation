SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Quantity: ', ps.ps_availqty, ' | Total Cost: $', 
           FORMAT(ps.ps_availqty * ps.ps_supplycost, 2), ' | Region: ', r.r_name) AS benchmark_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 20 AND 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment NOT LIKE '%good%')
ORDER BY 
    p.p_retailprice DESC
LIMIT 100;
