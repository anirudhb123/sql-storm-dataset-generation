WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        sh.level < 5
), 
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
), 
SupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(ss.total_available_qty, 0) AS total_available_qty,
    COALESCE(ts.total_sales, 0) AS total_sales,
    (CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        WHEN ts.total_sales < 10000 THEN 'Low Sales'
        ELSE 'High Sales'
    END) AS sales_category,
    sh.level
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ss ON ss.supplier_count > 0
LEFT JOIN 
    TotalSales ts ON ss.p_partkey = ts.l_partkey
JOIN 
    SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
WHERE 
    (r.r_name LIKE '%North%' OR r.r_name IS NULL)
    AND (ss.total_available_qty IS NOT NULL OR ts.total_sales IS NOT NULL)
ORDER BY 
    r.r_name, n.n_name, sales_category DESC;
