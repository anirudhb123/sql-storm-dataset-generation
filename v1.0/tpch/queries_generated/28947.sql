WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_type LIKE '%BRASS%'
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON s.s_suppkey = rs.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.supplier_count,
    r.total_acctbal,
    CONCAT(r.r_name, ' has ', r.supplier_count, ' top suppliers with a total account balance of $', FORMAT(r.total_acctbal, 2)) AS summary
FROM 
    TopSuppliers r
ORDER BY 
    r.total_acctbal DESC;
