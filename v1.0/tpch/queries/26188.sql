SELECT 
    s_name AS supplier_name, 
    SUM(ps_availqty) AS total_available_qty,
    COUNT(DISTINCT p_partkey) AS unique_parts_supplied,
    STRING_AGG(DISTINCT CONCAT(p_name, ' (', p_brand, ')'), ', ') AS supplied_part_details,
    n_name AS nation_name,
    CONCAT('Region: ', r_name, ', Supplier Address: ', s_address) AS detailed_info
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
    p.p_size > 50 AND 
    s.s_acctbal > 1000.00
GROUP BY 
    s.s_suppkey, s_name, n_name, r_name, s_address
ORDER BY 
    total_available_qty DESC, unique_parts_supplied DESC
LIMIT 10;
