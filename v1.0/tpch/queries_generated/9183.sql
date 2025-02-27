WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        COUNT(rs.s_suppkey) AS supplier_count,
        SUM(rs.total_value) AS total_supplier_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5 
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    COALESCE(ts.supplier_count, 0) AS supplier_count,
    COALESCE(ts.total_supplier_value, 0.00) AS total_supplier_value
FROM 
    region r
LEFT JOIN 
    TopSuppliers ts ON r.r_name = ts.r_name
ORDER BY 
    r.r_name;
