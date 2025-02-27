WITH RECURSIVE RecursiveCTE AS (
    SELECT n_nationkey, n_name, r_name, 1 AS level
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name = 'ASIA'

    UNION ALL

    SELECT n.n_nationkey, n.n_name, r.r_name, c.level + 1
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN RecursiveCTE c ON n.n_nationkey != c.n_nationkey
    WHERE c.level < 5
),
AggregatedData AS (
    SELECT
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_unit_price,
        SUM(l.l_quantity) AS total_quantity
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_nationkey
),
RankedCustomers AS (
    SELECT
        ad.c_nationkey,
        ad.total_sales,
        ad.order_count,
        ad.avg_unit_price,
        RANK() OVER (PARTITION BY ad.c_nationkey ORDER BY ad.total_sales DESC) AS sales_rank
    FROM AggregatedData ad
)
SELECT 
    rc.n_name,
    rc.r_name,
    COALESCE(rk.total_sales, 0) AS total_sales,
    COALESCE(rk.order_count, 0) AS order_count,
    COALESCE(rk.avg_unit_price, 0) AS avg_unit_price,
    rk.sales_rank
FROM region r
JOIN RecursiveCTE rc ON r.r_name = rc.r_name
LEFT JOIN RankedCustomers rk ON rc.n_nationkey = rk.c_nationkey
WHERE rk.sales_rank <= 5 OR rk.sales_rank IS NULL
ORDER BY rc.level, rc.n_name;
