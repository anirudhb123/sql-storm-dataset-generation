WITH RECURSIVE string_benchmark AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        LENGTH(s.s_name) AS name_length,
        SUBSTRING(s.s_name FROM 1 FOR 5) AS name_substring,
        REPLACE(s.s_comment, 'Supplier', 'Provider') AS modified_comment,
        CASE
            WHEN POSITION('Inc' IN s.s_name) > 0 THEN 'Incorporated'
            ELSE 'Non-Incorporated'
        END AS incorporation_status
    FROM supplier s
    WHERE LENGTH(s.s_comment) > 50

    UNION ALL

    SELECT 
        ps.ps_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_name FROM 1 FOR 5) AS name_substring,
        REPLACE(p.p_comment, 'part', 'component') AS modified_comment,
        CASE
            WHEN POSITION('Type' IN p.p_name) > 0 THEN 'Type Included'
            ELSE 'Type Missing'
        END AS type_status
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE LENGTH(p.p_comment) > 20
)
SELECT 
    s.s_suppkey,
    s.s_name AS supplier_name,
    s.name_length AS supplier_name_length,
    s.name_substring AS supplier_name_prefix,
    s.modified_comment AS supplier_comment_mod,
    s.incorporation_status AS supplier_incorporation_status,
    p.p_partkey,
    p.p_name AS part_name,
    p.name_length AS part_name_length,
    p.name_substring AS part_name_prefix,
    p.modified_comment AS part_comment_mod,
    p.type_status AS part_type_status
FROM string_benchmark s
JOIN string_benchmark p ON s.s_suppkey = p.ps_suppkey
ORDER BY s.s_name, p.p_name;
