
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        LENGTH(s.s_comment) > 50
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.s_comment,
        SUBSTRING(rs.s_comment, 1, 30) AS short_comment 
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_acctbal <= 3
)
SELECT 
    ps.ps_partkey,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(ps.ps_availqty) AS avg_avail_qty,
    LISTAGG(ts.short_comment, '; ') AS comments_summary
FROM 
    partsupp ps
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
GROUP BY 
    ps.ps_partkey, ts.s_suppkey, ts.s_name, ts.s_acctbal, ts.s_comment, ts.short_comment
ORDER BY 
    supplier_count DESC, total_supply_cost DESC
LIMIT 10;
