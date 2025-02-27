WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS parts_supplied
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
HighVolumeSuppliers AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY part_count DESC) AS rank
    FROM RankedSuppliers s
    WHERE part_count > 5
)
SELECT 
    s.s_name,
    s.region_name,
    s.part_count,
    s.parts_supplied
FROM 
    HighVolumeSuppliers s
WHERE 
    s.rank <= 10
ORDER BY 
    s.part_count DESC, s.s_name;
