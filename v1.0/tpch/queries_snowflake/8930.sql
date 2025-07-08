WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region,
        COUNT(rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rnk <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    t.region,
    t.supplier_count,
    t.total_acctbal,
    AVG(p.p_retailprice) AS avg_retail_price
FROM 
    TopSuppliers t
JOIN 
    partsupp ps ON t.supplier_count = (SELECT COUNT(*) FROM supplier WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = t.region)))
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
GROUP BY 
    t.region, t.supplier_count, t.total_acctbal
ORDER BY 
    t.total_acctbal DESC, t.region ASC;
