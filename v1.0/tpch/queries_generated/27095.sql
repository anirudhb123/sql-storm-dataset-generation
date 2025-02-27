WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation,
        rs.part_count,
        rs.total_available_quantity
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_within_nation <= 3
)
SELECT 
    fs.nation,
    STRING_AGG(CONCAT(fs.s_name, ' (Parts: ', fs.part_count, ', Available Qty: ', fs.total_available_quantity, ')'), ', ') AS supplier_details
FROM 
    FilteredSuppliers fs
GROUP BY 
    fs.nation
ORDER BY 
    fs.nation;
