WITH RECURSIVE string_benchmark AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address) AS full_info,
        LENGTH(s.s_name) + LENGTH(s.s_address) AS string_length,
        COALESCE(NULLIF(INSTR(s.s_name, 'Supplier'), 0), 0) AS position_supplier,
        COALESCE(NULLIF(INSTR(s.s_address, 'USA'), 0), 0) AS position_usa
    FROM supplier s
    UNION ALL
    SELECT 
        ps.ps_partkey,
        SUBSTRING(p.p_name, 1, 25) AS p_name,
        CONCAT('Part: ', p.p_name, ', Container: ', p.p_container) AS full_info,
        LENGTH(p.p_name) + LENGTH(p.p_container) AS string_length,
        COALESCE(NULLIF(INSTR(p.p_name, 'Part'), 0), 0) AS position_part,
        COALESCE(NULLIF(INSTR(p.p_container, 'BOX'), 0), 0) AS position_box
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    s.s_suppkey,
    COUNT(*) AS entry_count,
    MAX(string_length) AS max_string_length,
    SUM(CASE WHEN position_supplier > 0 THEN 1 ELSE 0 END) AS supplier_found,
    SUM(CASE WHEN position_usa > 0 THEN 1 ELSE 0 END) AS usa_found,
    MAX(full_info) AS longest_info
FROM (
    SELECT 
        s.s_suppkey,
        string_length,
        position_supplier,
        position_usa,
        full_info
    FROM string_benchmark
    WHERE s_suppkey IS NOT NULL
) AS benchmark
GROUP BY s_suppkey
ORDER BY entry_count DESC, max_string_length DESC;
