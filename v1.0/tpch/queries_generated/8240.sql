WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_costs,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name AS supplier_name,
        rs.total_costs
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.nation_name
    WHERE 
        rs.rank <= 3
)
SELECT 
    region_name,
    supplier_name,
    total_costs
FROM 
    TopSuppliers
ORDER BY 
    region_name, total_costs DESC;
