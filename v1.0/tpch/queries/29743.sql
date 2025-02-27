
WITH SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_count,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        STRING_AGG(p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
RegionNationSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        STRING_AGG(n.n_name, ', ') AS nation_names
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    s.s_suppkey,
    s.total_available_quantity,
    s.unique_parts_count,
    s.average_supply_cost,
    s.part_names,
    r.r_regionkey,
    r.r_name,
    r.total_nations,
    r.nation_names
FROM 
    SupplierPartSummary s
JOIN 
    RegionNationSummary r ON r.r_regionkey = (s.s_suppkey % 5 + 1)  
ORDER BY 
    s.total_available_quantity DESC, 
    r.r_name;
