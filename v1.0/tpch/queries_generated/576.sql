WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
AggregatedSales AS (
    SELECT 
        n.n_name AS nation_name,
        AVG(ss.total_sales) AS avg_sales,
        SUM(ss.total_sales) AS total_nation_sales
    FROM 
        SupplierSales ss
    JOIN 
        nation n ON ss.s_suppkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
FinalResults AS (
    SELECT 
        a.nation_name,
        a.avg_sales,
        a.total_nation_sales,
        CASE 
            WHEN a.total_nation_sales > 100000 THEN 'High Sales'
            WHEN a.total_nation_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales'
            ELSE 'Low Sales' 
        END AS sales_category
    FROM 
        AggregatedSales a
)

SELECT 
    f.nation_name,
    f.avg_sales,
    f.total_nation_sales,
    f.sales_category,
    COALESCE((SELECT 
                    MAX(total_sales) 
                FROM 
                    SupplierSales 
                WHERE 
                    sales_rank = 1 AND s_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = n.n_nationkey)), 0) AS max_supplier_sales
FROM 
    FinalResults f
FULL OUTER JOIN 
    nation n ON f.nation_name = n.n_name
WHERE 
    f.avg_sales IS NOT NULL OR n.n_name IS NULL
ORDER BY 
    f.total_nation_sales DESC, f.nation_name;
