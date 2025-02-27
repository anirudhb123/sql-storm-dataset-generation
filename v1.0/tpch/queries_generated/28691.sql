WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COUNT(ps.ps_partkey) AS total_parts, 
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        ns.n_name AS nation_name, 
        rs.s_name, 
        rs.total_parts, 
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    region_name, 
    nation_name, 
    s_name, 
    total_parts, 
    total_supplycost, 
    CONCAT(s_name, ' is among the top suppliers in ', nation_name, ', ', region_name, ' with ', total_parts, ' parts and a total supply cost of $', FORMAT(total_supplycost, 2)) AS supplier_info
FROM 
    TopSuppliers
ORDER BY 
    region_name, 
    nation_name, 
    total_supplycost DESC;
