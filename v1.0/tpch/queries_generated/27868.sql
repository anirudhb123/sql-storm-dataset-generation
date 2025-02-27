WITH PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        p.p_size,
        p.p_container,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_size, p.p_container
),
RegionData AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.name_length,
    ps.p_size,
    ps.p_container,
    ps.supplier_count,
    ps.total_supply_cost,
    rd.r_regionkey,
    rd.r_name AS region_name,
    rd.nation_count,
    rd.nation_names
FROM 
    PartStats ps
JOIN 
    region r ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        JOIN partsupp ps1 ON s.s_suppkey = ps1.ps_suppkey 
        WHERE ps1.ps_partkey = ps.p_partkey
        LIMIT 1
    )
JOIN 
    RegionData rd ON r.r_regionkey = rd.r_regionkey
WHERE 
    ps.total_supply_cost > 1000
ORDER BY 
    ps.name_length DESC, 
    ps.total_supply_cost DESC;
