WITH String_Processing AS (
    SELECT 
        p.p_name,
        s.s_name,
        c.c_name,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS description,
        LENGTH(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name)) AS total_length,
        SUBSTRING(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name), 1, 50) AS short_description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey 
    WHERE 
        p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100)
    ORDER BY 
        total_length DESC
)
SELECT 
    description,
    total_length
FROM 
    String_Processing
WHERE 
    total_length > 100
LIMIT 10;
