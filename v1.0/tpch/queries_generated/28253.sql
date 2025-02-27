WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
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
TopSuppliers AS (
    SELECT 
        r.r_name AS region,
        rs.s_name,
        rs.part_count,
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    region,
    s_name,
    part_count,
    total_supplycost,
    CONCAT('Supplier ', s_name, ' from ', region, ' has ', part_count, ' parts with total supply cost of $', total_supplycost) AS supplier_summary
FROM 
    TopSuppliers
ORDER BY 
    region, total_supplycost DESC;
