WITH StringManipulations AS (
    SELECT 
        p.p_name AS part_name,
        UPPER(SUBSTRING(p.p_comment, 1, 10)) AS truncated_comment_upper,
        LENGTH(p.p_name) AS name_length,
        REPLACE(p.p_name, ' ', '-') AS name_with_dashes
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size > 5)
),
NationAndSupplier AS (
    SELECT 
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        CONCAT(n.n_name, ' - ', s.s_name) AS nation_supplier
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
)
SELECT 
    sm.part_name,
    sm.truncated_comment_upper,
    sm.name_length,
    sm.name_with_dashes,
    ns.nation_supplier
FROM 
    StringManipulations sm
JOIN 
    NationAndSupplier ns ON LENGTH(sm.part_name) % 2 = LENGTH(ns.nation_supplier) % 2
ORDER BY 
    sm.name_length DESC, ns.nation_supplier;
