WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
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
        n.n_name, 
        rs.s_name, 
        rs.total_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rnk <= 5 AND n.n_nationkey = rs.s_nationkey
)
SELECT 
    n.r_name AS region, 
    COUNT(*) AS supplier_count, 
    AVG(total_value) AS average_value
FROM 
    HighValueSuppliers hvs
JOIN 
    region n ON n.r_regionkey = (SELECT n2.n_regionkey FROM nation n2 WHERE n2.n_name = hvs.n_name LIMIT 1)
GROUP BY 
    n.r_name
ORDER BY 
    supplier_count DESC, average_value DESC;
