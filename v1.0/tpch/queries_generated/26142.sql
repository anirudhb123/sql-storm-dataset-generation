WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_address,
        rs.nation_name,
        rs.part_count,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    fs.s_name,
    fs.nation_name,
    fs.part_count,
    fs.total_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    FilteredSuppliers fs
JOIN 
    partsupp ps ON fs.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    fs.s_name, fs.nation_name, fs.part_count, fs.total_supply_cost
ORDER BY 
    fs.total_supply_cost DESC;
