WITH RECURSIVE SalesData AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey, c.c_custkey
), RankedSales AS (
    SELECT 
        s.c_custkey,
        s.total_sales,
        s.sales_rank,
        n.n_name,
        CASE 
            WHEN s.sales_rank <= 10 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM SalesData s
    JOIN customer c ON s.c_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    n.r_name AS region,
    COUNT(DISTINCT rs.c_custkey) AS customer_count,
    SUM(rs.total_sales) AS total_sales,
    AVG(rs.total_sales) AS average_sales,
    COALESCE(MAX(CASE WHEN rs.customer_type = 'Top Customer' THEN rs.total_sales END), 0) AS max_top_customer_sales,
    COUNT(DISTINCT CASE WHEN rs.customer_type = 'Top Customer' THEN rs.c_custkey END) AS top_customer_count
FROM RankedSales rs
JOIN supplier s ON rs.c_custkey = s.s_suppkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > 100 AND p.p_size IS NOT NULL
GROUP BY n.r_name
ORDER BY total_sales DESC
LIMIT 5;
