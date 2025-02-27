WITH string_benchmark AS (
    SELECT 
        p.p_name AS part_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
        REPLACE(s.s_name, 'Supplier', 'Sup') AS modified_supplier_name,
        LENGTH(p.p_comment) AS comment_length,
        UPPER(p.p_mfgr) AS manufacturer_upper,
        LOWER(c.c_name) AS customer_lower,
        TRIM(c.c_comment) AS trimmed_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN customer c ON c.c_custkey = (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey = (
            SELECT l.l_orderkey 
            FROM lineitem l 
            WHERE l.l_partkey = p.p_partkey 
            LIMIT 1
        )
        LIMIT 1
    )
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size BETWEEN 1 AND 50
)
SELECT 
    COUNT(*) AS total_entries,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT region_nation) AS unique_region_nations,
    COUNT(*) FILTER (WHERE manufacturer_upper LIKE 'A%') AS mfgr_starts_with_a,
    COUNT(DISTINCT modified_supplier_name) AS unique_modified_supplier_names
FROM string_benchmark;
