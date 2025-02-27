WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        n.n_name, 
        rs.s_name, 
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rnk <= 3
)
SELECT 
    r_name, 
    n_name, 
    COUNT(s_name) AS top_supplier_count, 
    SUM(s_acctbal) AS total_acct_balance
FROM 
    TopSuppliers
GROUP BY 
    r_name, n_name
ORDER BY 
    r_name, top_supplier_count DESC;
