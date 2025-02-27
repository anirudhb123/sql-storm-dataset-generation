WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 3
)
SELECT 
    region_name,
    nation_name,
    COUNT(DISTINCT supplier_name) AS top_suppliers_count,
    SUM(total_supply_cost) AS total_cost_of_top_suppliers
FROM 
    TopSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    total_cost_of_top_suppliers DESC, region_name, nation_name;
