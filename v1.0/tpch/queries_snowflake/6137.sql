
WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_sales
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
),
CustomerSales AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS customer_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    rs.region_name,
    rs.total_sales,
    cs.customer_sales,
    (rs.total_sales - COALESCE(cs.customer_sales, 0)) AS sales_difference
FROM 
    RegionSales rs
LEFT JOIN 
    CustomerSales cs ON cs.c_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        JOIN region r ON n.n_regionkey = r.r_regionkey
        WHERE r.r_name = rs.region_name
    )
ORDER BY 
    rs.region_name;
