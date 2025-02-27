WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    region_name,
    nation_name,
    STRING_AGG(supplier_name, ', ') AS top_suppliers,
    SUM(total_supply_cost) AS total_cost
FROM 
    TopSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, total_cost DESC;
