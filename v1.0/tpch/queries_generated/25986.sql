SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS distinct_part_names,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    MIN(p.p_retailprice) AS min_part_retail_price,
    MAX(p.p_retailprice) AS max_part_retail_price
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_size > 10 AND s.s_acctbal > 500.00
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    supplier_count DESC, nation_name;
