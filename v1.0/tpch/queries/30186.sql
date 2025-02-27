WITH RECURSIVE RegionalSales AS (
    SELECT n.n_name AS nation_name, SUM(o.o_totalprice) AS total_sales, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY n.n_name
    UNION ALL
    SELECT r.r_name AS nation_name, SUM(o.o_totalprice) AS total_sales, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE r.r_name IS NOT NULL
    GROUP BY r.r_name
),
SalesRank AS (
    SELECT 
        nation_name,
        total_sales,
        customer_count,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionalSales
),
FilteredSales AS (
    SELECT 
        nation_name,
        total_sales,
        customer_count,
        sales_rank
    FROM SalesRank
    WHERE sales_rank <= 5
)
SELECT 
    f.nation_name,
    f.total_sales,
    f.customer_count,
    COALESCE(SUM(l.l_discount * l.l_extendedprice), 0) AS total_discounted_sales,
    CASE 
        WHEN SUM(l.l_quantity) > 0 THEN
            AVG(l.l_extendedprice / NULLIF(l.l_quantity, 0))
        ELSE 
            NULL 
    END AS avg_price_per_quantity
FROM FilteredSales f
LEFT JOIN lineitem l ON f.nation_name = (SELECT n.n_name FROM nation n JOIN supplier s ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey = l.l_suppkey)
GROUP BY f.nation_name, f.total_sales, f.customer_count
ORDER BY f.total_sales DESC;
