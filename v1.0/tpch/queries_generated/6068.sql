WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_nationkey
),
MaxPartCounts AS (
    SELECT 
        n.n_nationkey,
        MAX(part_count) AS max_part_count
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    rs.s_name,
    n.n_name AS nation_name,
    rs.total_supply_cost,
    rs.part_count,
    rs.rank_within_nation
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    MaxPartCounts m ON n.n_nationkey = m.n_nationkey AND rs.part_count = m.max_part_count
ORDER BY 
    n.n_name, rs.rank_within_nation;
