WITH StringBenchmarks AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name, ' ', n.n_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name, ' ', n.n_name)) AS combined_length,
        UPPER(CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name, ' ', n.n_name)) AS combined_upper,
        LOWER(CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name, ' ', n.n_name)) AS combined_lower
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        p.p_retailprice > 100 
        AND c.c_acctbal > 500 
        AND s.s_acctbal < 1000
)
SELECT 
    part_name,
    supplier_name,
    customer_name,
    nation_name,
    combined_string,
    combined_length,
    combined_upper,
    combined_lower
FROM 
    StringBenchmarks
ORDER BY 
    combined_length DESC
LIMIT 100;
