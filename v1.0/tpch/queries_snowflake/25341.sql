WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal, 
        p.p_name
    FROM 
        RankedSuppliers rs
    JOIN 
        part p ON rs.s_suppkey IN (
            SELECT 
                ps.ps_suppkey 
            FROM 
                partsupp ps 
            WHERE 
                ps.ps_partkey = p.p_partkey
        )
    WHERE 
        rs.rank <= 3
)
SELECT 
    f.s_name AS Supplier_Name,
    f.s_acctbal AS Account_Balance,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales
FROM 
    FilteredSuppliers f
JOIN 
    lineitem l ON f.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    f.s_name, f.s_acctbal
ORDER BY 
    Total_Sales DESC;