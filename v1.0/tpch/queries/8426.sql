
WITH RegionSales AS (
    SELECT r.r_name AS region_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY r.r_name
),
CustomerSales AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY c.c_nationkey
),
SalesSummary AS (
    SELECT 
        rs.region_name,
        COALESCE(cs.total_sales, 0) AS customer_sales,
        rs.total_sales AS region_sales
    FROM RegionSales rs
    LEFT JOIN CustomerSales cs ON rs.region_name = (
        SELECT r.r_name 
        FROM region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        WHERE n.n_nationkey = cs.c_nationkey
    )
)
SELECT 
    region_name,
    SUM(customer_sales) AS total_customer_sales,
    SUM(region_sales) AS total_region_sales,
    SUM(customer_sales) / NULLIF(SUM(region_sales), 0) AS sales_ratio
FROM SalesSummary
GROUP BY region_name
ORDER BY region_name;
