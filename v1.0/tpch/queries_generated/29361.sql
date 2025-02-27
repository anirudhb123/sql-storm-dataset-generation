WITH ProcessedData AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_name AS supplier_name, 
        CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name) AS supplier_product_info,
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        REPLACE(p.p_type, ' ', '_') AS type_with_underscores
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 100.00
)
SELECT 
    r.r_name AS region_name,
    COUNT(*) AS total_products,
    STRING_AGG(DISTINCT supplier_product_info, '; ') AS suppliers_products,
    MIN(short_comment) AS first_comment,
    MAX(type_with_underscores) AS max_type
FROM 
    ProcessedData pd
JOIN 
    supplier s ON pd.supplier_name = s.s_name
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_products DESC;
