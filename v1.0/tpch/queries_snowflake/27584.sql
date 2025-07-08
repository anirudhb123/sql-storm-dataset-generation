WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        rs.s_suppkey, rs.s_name, n.n_name
)
SELECT 
    fs.s_suppkey,
    fs.s_name,
    fs.n_name,
    fs.total_supply_cost,
    fs.part_count,
    CONCAT('Supplier ', fs.s_name, ' from ', fs.n_name, ' has total supply cost of $', CAST(fs.total_supply_cost AS CHAR), ' for ', fs.part_count, ' unique parts.') AS summary
FROM 
    FilteredSuppliers fs
ORDER BY 
    fs.total_supply_cost DESC;
