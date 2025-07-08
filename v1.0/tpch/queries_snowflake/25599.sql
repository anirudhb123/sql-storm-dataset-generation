
WITH RankedSuppliers AS (
    SELECT
        s.s_name,
        s.s_acctbal,
        p.p_type,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
)

SELECT 
    rs.p_type,
    LISTAGG(rs.s_name, ', ') WITHIN GROUP (ORDER BY rs.s_acctbal DESC) AS top_suppliers,
    SUM(rs.s_acctbal) AS total_acctbal
FROM 
    RankedSuppliers rs
WHERE 
    rs.rank <= 3
GROUP BY 
    rs.p_type
ORDER BY 
    total_acctbal DESC;
