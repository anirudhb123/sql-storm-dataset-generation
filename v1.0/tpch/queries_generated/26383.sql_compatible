
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
), HighCostSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    region_name,
    nation_name,
    STRING_AGG(supplier_name, ', ') AS top_suppliers,
    SUM(total_cost) AS total_cost
FROM 
    HighCostSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, total_cost DESC;
