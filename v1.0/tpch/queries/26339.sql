WITH StringAgg AS (
    SELECT 
        s.s_name AS supplier_name,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' - ', ps.ps_supplycost, ' - ', ps.ps_comment), '; ') AS aggregated_info 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name
),
TotalStringLen AS (
    SELECT 
        SUM(LENGTH(aggregated_info)) AS total_length 
    FROM 
        StringAgg
),
SupplierInfo AS (
    SELECT 
        s.s_name, 
        r.r_name AS region_name, 
        LENGTH(s.s_name) + LENGTH(r.r_name) AS combined_length 
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    s_info.s_name,
    s_info.region_name,
    tsl.total_length,
    s_info.combined_length,
    CASE 
        WHEN s_info.combined_length > 50 THEN 'Long'
        ELSE 'Short'
    END AS length_category
FROM 
    SupplierInfo s_info,
    TotalStringLen tsl
WHERE 
    tsl.total_length > 0
ORDER BY 
    s_info.combined_length DESC;
