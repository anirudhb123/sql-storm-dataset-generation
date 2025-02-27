WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM 
        supplier s
    INNER JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal > 5000 AND sh.level < 5
),
DailySales AS (
    SELECT 
        l.l_shipdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY 
        l.l_shipdate
),
SupplierAverage AS (
    SELECT 
        sh.s_nationkey,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        SupplierHierarchy sh
    LEFT JOIN 
        partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        sh.s_nationkey
)
SELECT 
    r.r_name,
    SUM(ds.total_sales) AS yearly_sales,
    AVG(sa.avg_price) AS average_supplier_price,
    COUNT(DISTINCT c.c_custkey) AS active_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    DailySales ds ON ds.l_shipdate >= '2023-01-01' AND ds.l_shipdate < '2024-01-01'
LEFT JOIN 
    SupplierAverage sa ON sa.s_nationkey = n.n_nationkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    s.s_acctbal IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(ds.total_sales) > 1000000 
ORDER BY 
    yearly_sales DESC;
