WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(rs.s_suppkey) AS supplier_count,
        SUM(rs.total_value) AS total_supplier_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    r_name, 
    supplier_count, 
    total_supplier_value,
    AVG(total_supplier_value) OVER() AS avg_value_per_region,
    SUM(total_supplier_value) OVER() AS grand_total_value
FROM 
    HighValueSuppliers
ORDER BY 
    total_supplier_value DESC;
