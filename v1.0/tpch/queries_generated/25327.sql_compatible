
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk,
        s.s_nationkey
    FROM 
        supplier s
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rnk <= 5  
),
SupplierParts AS (
    SELECT 
        fps.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_container, ')'), ', ') AS parts_list
    FROM 
        FilteredSuppliers fps
    JOIN 
        partsupp ps ON fps.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        fps.s_suppkey
)
SELECT 
    fps.s_name,
    fps.nation_name,
    sp.part_count,
    sp.parts_list,
    fps.s_acctbal
FROM 
    FilteredSuppliers fps
JOIN 
    SupplierParts sp ON fps.s_suppkey = sp.s_suppkey
ORDER BY 
    fps.nation_name, 
    sp.part_count DESC;
