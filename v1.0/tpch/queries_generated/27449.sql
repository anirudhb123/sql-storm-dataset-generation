WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(SUBSTRING(p.p_name FROM 1 FOR 3), '...', SUBSTRING(p.p_name FROM LENGTH(p.p_name) - 2 FOR 3)) AS truncated_name,
        REPLACE(p.p_comment, 'best', 'excellent') AS modified_comment
    FROM 
        part p
),
SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        LENGTH(s.s_name) AS supplier_name_length,
        LENGTH(s.s_comment) AS supplier_comment_length,
        LOWER(s.s_name) AS lower_supplier_name,
        INITCAP(s.s_comment) AS capitalized_supplier_comment
    FROM 
        supplier s
),
CombinedMetrics AS (
    SELECT 
        sm.p_partkey,
        sm.name_length,
        sm.comment_length,
        sm.truncated_name,
        sm.modified_comment,
        supp.supplier_name_length,
        supp.supplier_comment_length,
        supp.lower_supplier_name,
        supp.capitalized_supplier_comment
    FROM 
        StringMetrics sm
    JOIN 
        SupplierMetrics supp ON sm.p_partkey % 10 = supp.s_supplier_name_length % 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    sm.truncated_name,
    sm.modified_comment,
    s.s_name,
    s.lower_supplier_name,
    s.capitalized_supplier_comment 
FROM 
    part p
JOIN 
    CombinedMetrics sm ON p.p_partkey = sm.p_partkey
JOIN 
    supplier s ON sm.supplier_name_length = LENGTH(s.s_name)
ORDER BY 
    sm.name_length DESC, 
    sm.comment_length DESC;
