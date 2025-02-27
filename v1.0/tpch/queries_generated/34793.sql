WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal,
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        SalesHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        sh.level < 3
),
RegionSales AS (
    SELECT 
        r.r_name, 
        SUM(o.o_totalprice) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON o.o_custkey = c.c_custkey
    GROUP BY 
        r.r_name
),
PartSupplierSales AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    rh.s_suppkey,
    rh.s_name,
    rh.s_acctbal,
    rs.total_sales,
    pss.supplier_sales,
    CASE 
        WHEN pss.supplier_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    SalesHierarchy rh
LEFT JOIN 
    RegionSales rs ON 1=1 
LEFT JOIN 
    PartSupplierSales pss ON pss.p_partkey = rh.s_suppkey
WHERE 
    rh.s_acctbal > 5000
ORDER BY 
    rh.level, rs.total_sales DESC;
