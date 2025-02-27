WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        STRING_AGG(CONCAT(p.p_name, ' - ', s.s_name, ' (', s.s_phone, ')'), '; ') AS suppliers_info,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
),
FilteredRegions AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        r.r_comment,
        STRING_AGG(n.n_name, ', ') AS nations
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_name, r.r_comment
)
SELECT 
    sr.p_partkey,
    sr.suppliers_info,
    sr.total_supply_cost,
    fr.r_name,
    fr.nations
FROM 
    StringAggregation sr
JOIN 
    FilteredRegions fr ON (sr.total_supply_cost > 1000 AND sr.p_partkey % 10 = 0)
ORDER BY 
    sr.total_supply_cost DESC;
