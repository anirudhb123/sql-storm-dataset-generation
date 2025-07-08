
WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        LISTAGG(CONCAT(p.p_name, ' from ', s.s_name, ' (', s.s_nationkey, ') - ', p.p_comment), '; ') AS part_supplier_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
),
NationInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        r.r_comment AS region_comment
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sa.part_supplier_info,
    ni.n_name,
    ni.region_name,
    ni.region_comment
FROM 
    StringAggregation sa
JOIN 
    NationInfo ni ON sa.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ni.n_nationkey) LIMIT 1);
