SELECT 
    CONCAT('Supplier: ', s_name, ' from nation: ', n_name, 
           ' provides part: ', p_name, ' of type: ', p_type, 
           ' which costs: $', FORMAT(ps_supplycost, 2), 
           ' and is available in quantity: ', ps_availqty, 
           ' (Comment: ', ps_comment, ')') AS supplier_part_info
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 100.00 AND 
    ps.ps_availqty < 50
ORDER BY 
    p.p_name, n.n_name;
