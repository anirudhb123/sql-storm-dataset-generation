WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
SalesSummary AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        SUM(ts.total_sales) AS total_nation_sales,
        SUM(ss.supplier_sales) AS total_supplier_sales
    FROM 
        TotalSales ts
    JOIN 
        partsupp ps ON ts.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region,
    nation,
    total_nation_sales,
    total_supplier_sales,
    CASE 
        WHEN total_nation_sales > total_supplier_sales THEN 'Higher Sales in Nation'
        ELSE 'Higher Sales in Supplier'
    END AS sales_comparison
FROM 
    SalesSummary
ORDER BY 
    region, nation;
