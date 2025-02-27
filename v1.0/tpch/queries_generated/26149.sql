WITH PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
RegionWiseStats AS (
    SELECT 
        r.r_name AS region,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(p.total_available_qty) AS total_available_qty_region,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        PartStats p ON n.n_nationkey = p.p_partkey
    GROUP BY 
        r.r_name
)
SELECT 
    rws.region,
    rws.nation_count,
    rws.total_available_qty_region,
    rws.part_names
FROM 
    RegionWiseStats rws
WHERE 
    rws.total_available_qty_region > 1000
ORDER BY 
    rws.region;
