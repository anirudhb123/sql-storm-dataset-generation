WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ss.total_sales
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    t.s_suppkey, 
    t.s_name, 
    t.s_acctbal, 
    t.total_sales, 
    r.r_name
FROM 
    TopSuppliers t
JOIN 
    nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = t.s_suppkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'N%'
ORDER BY 
    t.total_sales DESC;
