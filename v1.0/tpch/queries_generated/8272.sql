WITH RegionalSales AS (
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        r.r_name
),

RankedSales AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)

SELECT 
    rs.region_name,
    rs.total_sales,
    rs.sales_rank,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    RankedSales rs
JOIN 
    orders o ON rs.region_name = (SELECT r.r_name FROM region r JOIN nation n ON r.r_regionkey = n.n_regionkey JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = o.o_custkey)
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    rs.region_name, rs.total_sales, rs.sales_rank
ORDER BY 
    rs.sales_rank;
