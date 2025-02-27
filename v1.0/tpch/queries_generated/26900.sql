SELECT 
    CONCAT('Supplier: ', s_name, ', Country: ', n_name, 
           ', Part: ', p_name, ', Price: $', FORMAT(ps_supplycost, 2), 
           ', Available Quantity: ', ps_availqty) AS supplier_part_info,
    LENGTH(CONCAT('Supplier: ', s_name, ', Country: ', n_name, 
                  ', Part: ', p_name, ', Price: $', FORMAT(ps_supplycost, 2), 
                  ', Available Quantity: ', ps_availqty)) AS info_length
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    LENGTH(s.s_comment) > 50 
    AND LENGTH(n.n_comment) < 100 
    AND p.p_retailprice > 100
ORDER BY 
    info_length DESC
LIMIT 10;
