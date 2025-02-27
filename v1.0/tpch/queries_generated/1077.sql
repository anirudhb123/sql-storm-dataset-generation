WITH AggregatedSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_partkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
BestSellingProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(a.total_sales, 0) AS total_sales
    FROM 
        part p
    LEFT JOIN 
        AggregatedSales a ON p.p_partkey = a.ps_partkey
    WHERE 
        p.p_retailprice > 50.00
)
SELECT 
    n.n_name AS supplier_nation,
    COUNT(DISTINCT sd.s_suppkey) AS supplier_count,
    SUM(bsp.total_sales) AS total_best_selling_sales,
    AVG(bsp.total_sales) AS avg_best_selling_sales
FROM 
    SupplierDetails sd
JOIN 
    nation n ON sd.s_nationkey = n.n_nationkey
JOIN 
    BestSellingProducts bsp ON sd.supplied_parts > 0 
WHERE 
    sd.supplied_parts > 5
GROUP BY 
    n.n_name
ORDER BY 
    total_best_selling_sales DESC
LIMIT 10;
