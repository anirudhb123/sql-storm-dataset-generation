WITH supplier_info AS (
    SELECT 
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        LENGTH(TRIM(s.s_comment)) AS comment_length,
        CONCAT(s.s_name, ', ', s.s_address, ', ', n.n_name, ', ', r.r_name) AS full_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
part_info AS (
    SELECT 
        p.p_name,
        p.p_type,
        p.p_brand,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_availqty,
        STRING_AGG(TRIM(ps.ps_comment), '; ') AS combined_comments
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, p.p_type, p.p_brand
)
SELECT 
    si.s_name,
    si.nation_name,
    pi.p_name,
    pi.p_type,
    pi.p_brand,
    si.comment_length,
    pi.avg_supplycost,
    pi.total_availqty,
    pi.combined_comments
FROM 
    supplier_info si
JOIN 
    part_info pi ON si.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
WHERE 
    si.comment_length > 100
ORDER BY 
    si.nation_name, pi.avg_supplycost DESC;
