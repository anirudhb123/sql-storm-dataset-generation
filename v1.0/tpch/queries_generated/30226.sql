WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000
), 

AggregatedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS distinct_part_count
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
),

SuppliersWithSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(ag.total_sales, 0) AS total_sales,
        ag.distinct_part_count
    FROM supplier s
    LEFT JOIN AggregatedSales ag ON ag.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_nationkey = s.s_nationkey
            AND c.c_mktsegment = 'BUILDING'
            FETCH FIRST 1 ROW ONLY
        )
    )
),

RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.distinct_part_count,
        RANK() OVER (PARTITION BY s.distinct_part_count ORDER BY s.total_sales DESC) AS sales_rank
    FROM SuppliersWithSales s
)

SELECT 
    sr.s_suppkey,
    sr.s_name,
    sr.total_sales,
    sr.distinct_part_count,
    CASE WHEN sr.sales_rank <= 5 THEN 'Top Supplier' ELSE 'Other' END AS rank_category,
    r.r_name AS region_name
FROM RankedSuppliers sr
JOIN nation n ON n.n_nationkey = sr.s_nationkey
JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE n.n_name IS NOT NULL
ORDER BY total_sales DESC, sr.s_name;
