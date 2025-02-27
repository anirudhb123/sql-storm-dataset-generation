WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 10000
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT rs.s_name) AS SupplierCount,
    STRING_AGG(DISTINCT rs.p_name, '; ') AS Products,
    AVG(rs.s_acctbal) AS AvgAccountBalance
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.rnk <= 3
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    r.r_name, n.n_name;
