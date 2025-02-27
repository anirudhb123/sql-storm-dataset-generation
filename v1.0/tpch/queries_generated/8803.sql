WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_cost DESC) AS supplier_rank
    FROM 
        SupplierSummary
)
SELECT 
    r.r_name AS region_name,
    t.nation_name,
    t.s_name AS supplier_name,
    t.total_available_quantity,
    t.total_cost
FROM 
    TopSuppliers t
JOIN 
    nation n ON t.nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.supplier_rank <= 3
ORDER BY 
    r.region_name, t.nation_name, t.total_cost DESC;
