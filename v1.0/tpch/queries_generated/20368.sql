WITH RECURSIVE RegionSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        r.r_name
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total) FROM (
            SELECT 
                SUM(l_extendedprice * (1 - l_discount)) AS total
            FROM
                lineitem
            GROUP BY
                l_orderkey
            ) AS avg_sales)
),
DistinctCustomers AS (
    SELECT DISTINCT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING'
),
SalesSummary AS (
    SELECT
        r.region_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM
        RegionSales r
    LEFT JOIN orders o ON r.region_name = (
        SELECT n.r_name FROM nation n JOIN region ra ON n.n_regionkey = ra.r_regionkey WHERE n.n_nationkey IN (
            SELECT s_nationkey FROM supplier s WHERE s.s_suppkey IN (
                SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
                    SELECT p_partkey FROM part
                )
            )
        )
    )
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        r.region_name
)
SELECT
    d.c_name,
    s.region_name,
    s.total_orders,
    s.total_revenue,
    CASE 
        WHEN s.total_revenue = 0 THEN 'No Revenue'
        ELSE 'Revenue Earned'
    END AS revenue_status
FROM 
    DistinctCustomers d
JOIN SalesSummary s ON d.c_custkey IN (
    SELECT DISTINCT o.o_custkey
    FROM orders o 
    WHERE o.o_orderstatus IN ('O', 'F')
)
ORDER BY 
    s.total_revenue DESC, 
    d.c_name ASC;

