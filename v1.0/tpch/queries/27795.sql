WITH supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        UPPER(s.s_name) AS upper_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        STRING_AGG(DISTINCT p.p_comment, '; ') AS all_comments
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
)
SELECT 
    si.s_suppkey,
    si.s_name,
    si.nation,
    si.region,
    si.s_acctbal,
    ps.p_partkey,
    ps.p_name,
    ps.avg_supplycost,
    ps.all_comments,
    si.comment_length,
    si.upper_name
FROM 
    supplier_info si
JOIN 
    part_summary ps ON si.s_suppkey IN (
        SELECT 
            psup.ps_suppkey 
        FROM 
            partsupp psup
        WHERE 
            psup.ps_partkey IN (
                SELECT 
                    p.p_partkey 
                FROM 
                    part p 
                WHERE 
                    p.p_size > 20
            )
    )
ORDER BY 
    si.s_acctbal DESC, 
    ps.avg_supplycost ASC
LIMIT 100;
