WITH RECURSIVE RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        1 AS level
    FROM
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        r.r_name
    UNION ALL
    SELECT
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        level + 1
    FROM
        RegionalSales rs
    JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN supplier s ON p.p_partkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY
        r.r_name
),
FilteredSales AS (
    SELECT
        region_name,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
),
FinalSales AS (
    SELECT
        region_name,
        total_sales
    FROM
        FilteredSales
    WHERE
        sales_rank <= 5
)
SELECT
    f.region_name,
    f.total_sales,
    COALESCE(f.total_sales / NULLIF((SELECT SUM(total_sales) FROM FilteredSales), 0), 0) AS sales_percentage,
    CASE
        WHEN f.total_sales > 1000000 THEN 'High'
        WHEN f.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM
    FinalSales f
LEFT JOIN customer c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'F')
ORDER BY f.total_sales DESC;
