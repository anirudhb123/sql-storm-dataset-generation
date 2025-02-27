WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_supply_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.n_nationkey)
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 3  
)
SELECT 
    ts.region_name, 
    ts.nation_name, 
    ts.supplier_name, 
    ts.total_supply_value
FROM 
    TopSuppliers ts
ORDER BY 
    ts.region_name, 
    ts.nation_name, 
    ts.total_supply_value DESC;