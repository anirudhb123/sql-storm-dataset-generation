WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.total_supply_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON n.n_name = rs.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    r.r_name AS region,
    COUNT(ts.s_name) AS top_supplier_count,
    SUM(ts.total_supply_value) AS total_value_of_top_suppliers
FROM 
    region r
LEFT JOIN 
    TopSuppliers ts ON r.r_name = ts.r_name
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
