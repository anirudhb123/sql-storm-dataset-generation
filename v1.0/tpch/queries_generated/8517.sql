WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionSales
)
SELECT 
    r.region_name,
    r.total_sales,
    r.sales_rank,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    RankedSales r
LEFT JOIN 
    customer c ON r.region_name = (SELECT n.r_name FROM nation n 
                                    JOIN region r ON n.n_regionkey = r.r_regionkey 
                                    WHERE r.r_name = r.region_name LIMIT 1)
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.region_name, r.total_sales, r.sales_rank
ORDER BY 
    r.sales_rank;
