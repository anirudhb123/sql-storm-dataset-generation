WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        p.p_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, p.p_name
),
FilteredSuppliers AS (
    SELECT 
        rs.nation_name,
        rs.s_name,
        rs.p_name,
        rs.total_availqty,
        rs.part_count
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 3
)
SELECT 
    nation_name,
    STRING_AGG(s_name || ' supplies ' || p_name || ' with total available quantity: ' || total_availqty, '; ') AS supplier_summary
FROM 
    FilteredSuppliers
GROUP BY 
    nation_name
ORDER BY 
    nation_name;
