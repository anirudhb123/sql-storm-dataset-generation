
WITH RecursiveStringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        CHAR_LENGTH(p.p_name) AS name_length,
        TRIM(REPLACE(p.p_comment, ' ', '')) AS trimmed_comment,
        (SELECT COUNT(*) FROM supplier s WHERE s.s_name LIKE '%' || SUBSTRING(p.p_name, 1, 5) || '%') AS similar_suppliers
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
AggregatedData AS (
    SELECT 
        n.n_name AS nation_name,
        STRING_AGG(LPAD(s.s_name, 20, ' '), '') AS padded_supplier_names,
        SUM(sr.name_length) AS total_name_length,
        AVG(sr.similar_suppliers) AS avg_similar_suppliers
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        RecursiveStringProcessing sr ON sr.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey LIMIT 1)
    GROUP BY 
        n.n_name
)
SELECT 
    nation_name,
    padded_supplier_names,
    total_name_length,
    avg_similar_suppliers
FROM 
    AggregatedData
ORDER BY 
    total_name_length DESC;
