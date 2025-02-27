WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
FilteredSales AS (
    SELECT 
        nation_name,
        total_sales,
        customer_count
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    f.nation_name,
    f.total_sales,
    COALESCE(
        (SELECT SUM(ps_supplycost * ps_availqty) 
         FROM partsupp ps 
         WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#39')), 
        0) AS inventory_value,
    CASE 
        WHEN f.customer_count > 100 THEN 'High Volume'
        WHEN f.customer_count BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM 
    FilteredSales f
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = f.nation_name)
WHERE 
    f.total_sales > (SELECT AVG(total_sales) FROM FilteredSales) OR f.nation_name IS NULL
ORDER BY 
    f.total_sales DESC;
