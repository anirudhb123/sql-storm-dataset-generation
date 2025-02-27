WITH processed_part_names AS (
    SELECT 
        p.p_partkey, 
        UPPER(p.p_name) AS upper_name, 
        LENGTH(p.p_name) AS name_length, 
        SUBSTR(p.p_name, 1, 10) AS name_prefix, 
        REPLACE(p.p_name, ' ', '_') AS name_with_underscores
    FROM 
        part p
),
nation_info AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region_name, 
        LENGTH(n.n_comment) AS comment_length
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
supplier_summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        LENGTH(s.s_comment) AS supplier_comment_length,
        SUBSTR(s.s_name, 1, 5) AS supplier_name_prefix
    FROM 
        supplier s
),
final_benchmark AS (
    SELECT 
        p.upper_name, 
        p.name_length, 
        p.name_prefix, 
        n.n_name, 
        n.region_name, 
        s.s_name AS supplier_name,
        s.supplier_comment_length
    FROM 
        processed_part_names p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier_summary s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation_info n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    upper_name, 
    name_length, 
    name_prefix, 
    n_name AS nation, 
    region_name, 
    supplier_name, 
    supplier_comment_length
FROM 
    final_benchmark
WHERE 
    name_length > 5 
ORDER BY 
    region_name, 
    upper_name;
