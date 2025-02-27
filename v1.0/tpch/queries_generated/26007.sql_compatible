
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUBSTRING(s.s_comment, 1, 30) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        s.s_nationkey
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(rs.s_suppkey) AS supplier_count, 
        SUM(rs.s_acctbal) AS total_acct_bal,
        STRING_AGG(rs.short_comment, '; ') AS comments_summary
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    region_name, 
    supplier_count, 
    total_acct_bal, 
    CONCAT('Total suppliers: ', supplier_count, ', Total account balance: ', total_acct_bal, '. Comments: ', comments_summary) AS detailed_info
FROM 
    TopSuppliers
ORDER BY 
    supplier_count DESC, total_acct_bal DESC;
