WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        r.r_name, 
        n.n_name, 
        rs.s_name, 
        rs.total_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rank <= 3 AND n.n_nationkey = rs.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ts.s_name AS supplier_name,
    ts.total_value
FROM 
    TopSuppliers ts
JOIN 
    region r ON ts.r_name = r.r_name
JOIN 
    nation n ON ts.n_name = n.n_name
ORDER BY 
    r.r_name, n.n_name, ts.total_value DESC;
