WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        lineitem
    GROUP BY 
        l_partkey
),
SupplierDetails AS (
    SELECT 
        ps.partkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        partkey,
        s_name,
        s_acctbal
    FROM 
        SupplierDetails
    WHERE 
        rank = 1
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    COALESCE(ts.total_sales, 0) AS total_sales,
    ts.total_sales * 0.1 AS projected_revenue,
    CASE 
        WHEN ts.total_sales IS NOT NULL AND ts.total_sales > 1000 THEN 'High'
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        ELSE 'Low'
    END AS sales_category,
    ns.n_name AS supplier_nation
FROM 
    part p
LEFT JOIN 
    TotalSales ts ON p.p_partkey = ts.l_partkey
LEFT JOIN 
    TopSuppliers top_s ON p.p_partkey = top_s.partkey
JOIN 
    nation ns ON ns.n_nationkey = (
        SELECT 
            s_nationkey 
        FROM 
            supplier 
        WHERE 
            s_name = top_s.s_name
        LIMIT 1
    )
WHERE 
    p.p_retailprice > 20.00
ORDER BY 
    projected_revenue DESC
LIMIT 50;
