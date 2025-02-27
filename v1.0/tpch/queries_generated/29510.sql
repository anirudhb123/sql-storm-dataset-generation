WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT 
    r.r_name,
    SUM(CASE WHEN rs.rn = 1 THEN rs.ps_supplycost ELSE 0 END) AS Highest_Cost,
    COUNT(DISTINCT CASE WHEN rs.rn = 1 THEN rs.s_suppkey END) AS Number_of_Highest_Cost_Suppliers,
    CASE 
        WHEN SUM(CASE WHEN rs.rn = 1 THEN rs.ps_supplycost ELSE 0 END) > 10000 THEN 'High'
        ELSE 'Low'
    END AS Cost_Category
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    Highest_Cost DESC;
