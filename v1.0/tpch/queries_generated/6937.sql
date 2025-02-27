WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT 
        r.r_name,
        n.n_name,
        s.s_name,
        rs.supplier_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(s.s_suppkey) AS top_suppliers_count,
    SUM(s.supplier_cost) AS total_cost
FROM 
    HighCostSuppliers s
JOIN 
    region r ON s.r_name = r.r_name
JOIN 
    nation n ON s.n_name = n.n_name
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_cost DESC
LIMIT 10;
