WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    
    UNION ALL
    
    SELECT 
        p.s_suppkey,
        p.s_name,
        p.s_nationkey,
        p.s_acctbal,
        sh.level + 1
    FROM 
        supplier p
    JOIN 
        SupplierHierarchy sh ON p.s_nationkey = sh.s_nationkey
    WHERE 
        p.s_acctbal > sh.s_acctbal
),
SalesData AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
MaxSales AS (
    SELECT 
        MAX(total_sales) AS max_sales
    FROM 
        SalesData
)
SELECT 
    r.r_name,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM 
    region r
LEFT JOIN 
    SalesData sd ON r.r_regionkey = sd.c_nationkey
LEFT JOIN 
    supplier s ON s.s_nationkey = sd.c_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
WHERE 
    sd.total_sales = (SELECT max_sales FROM MaxSales)
GROUP BY 
    r.r_name, sd.total_sales, sd.order_count
ORDER BY 
    r.r_name;
