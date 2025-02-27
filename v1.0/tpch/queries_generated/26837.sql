SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Price: ', ps.ps_supplycost, 
           ' | Quantity Available: ', ps.ps_availqty) AS benchmark_string
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    CAST(ps.ps_supplycost AS CHAR) LIKE '%123%' 
    AND UPPER(s.s_name) LIKE '%ACME%' 
    AND CHAR_LENGTH(p.p_comment) > 10
ORDER BY 
    ps.ps_availqty DESC
LIMIT 100;
