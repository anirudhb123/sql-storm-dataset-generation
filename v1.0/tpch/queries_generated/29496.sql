WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        c.c_name,
        n.n_name AS nation,
        r.r_name AS region,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS concatenated_info,
        LENGTH(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name)) AS info_length
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
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nation,
    region,
    COUNT(*) AS entry_count,
    AVG(info_length) AS average_length,
    MIN(info_length) AS min_length,
    MAX(info_length) AS max_length
FROM 
    StringProcessing
GROUP BY 
    nation, region
ORDER BY 
    entry_count DESC, average_length DESC;
