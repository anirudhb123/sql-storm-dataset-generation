WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, 1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE 'A%'

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_supkey = sh.s_suppkey
),
AggregatedSales AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY l.l_partkey
),
FilteredParts AS (
    SELECT p.*, 
           CASE 
               WHEN p.p_retailprice IS NULL THEN 'Unknown' 
               WHEN p.p_retailprice < 50 THEN 'Cheap' 
               WHEN p.p_retailprice BETWEEN 50 AND 150 THEN 'Moderate' 
               ELSE 'Expensive' 
           END AS price_category
    FROM part p
),
FinalResults AS (
    SELECT
        f.p_partkey,
        f.p_name,
        s.s_name,
        a.total_sales,
        a.total_quantity,
        f.price_category,
        ROW_NUMBER() OVER (PARTITION BY f.p_size ORDER BY a.total_sales DESC) AS sales_rank,
        COUNT(DISTINCT c.c_custkey) OVER () AS total_customers
    FROM FilteredParts f
    LEFT JOIN AggregatedSales a ON f.p_partkey = a.l_partkey
    LEFT JOIN supplier s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = f.p_partkey 
        AND ps.ps_availqty < 100
    )
    JOIN customer c ON s.s_nationkey = c.c_nationkey
)
SELECT 
    p.*,
    COALESCE(sales_rank, 0) AS sales_rank,
    COALESCE(total_customers, 0) AS total_customers,
    CASE 
        WHEN price_category = 'Cheap' AND total_sales > 1000 THEN 'High Demand Cheap' 
        WHEN price_category = 'Expensive' AND total_sales < 500 THEN 'Slow Moving Expensive'
        ELSE 'Normal'
    END AS market_segment 
FROM FinalResults p
ORDER BY p.price_category, p.total_sales DESC
LIMIT 50 OFFSET 10;
