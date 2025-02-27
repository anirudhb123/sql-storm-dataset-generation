WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
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
        rs.nation_name,
        COUNT(*) AS number_of_top_suppliers,
        SUM(rs.total_supply_cost) AS total_cost_of_top_suppliers
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supply_rank <= 5
    GROUP BY 
        rs.nation_name
)
SELECT 
    r.r_name AS region_name,
    COALESCE(ts.number_of_top_suppliers, 0) AS number_of_top_suppliers,
    COALESCE(ts.total_cost_of_top_suppliers, 0) AS total_cost_of_top_suppliers,
    (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)) AS total_suppliers_in_region
FROM 
    region r
LEFT JOIN 
    TopSuppliers ts ON r.r_name = ts.nation_name
ORDER BY 
    r.r_name;
