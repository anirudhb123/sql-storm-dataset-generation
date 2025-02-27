
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
), NationSales AS (
    SELECT 
        n.n_name,
        SUM(r.total_sales) AS national_sales
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales r ON s.s_suppkey = r.s_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name AS nation_name,
    ns.national_sales,
    rs.s_name AS top_supplier,
    rs.total_sales AS top_supplier_sales
FROM 
    NationSales ns
LEFT JOIN 
    RankedSales rs ON rs.total_sales = (SELECT MAX(total_sales) FROM SupplierSales WHERE total_sales <= ns.national_sales)
WHERE 
    ns.national_sales IS NOT NULL
ORDER BY 
    ns.national_sales DESC, rs.total_sales DESC;
