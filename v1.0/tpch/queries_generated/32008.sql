WITH RECURSIVE regional_sales AS (
    SELECT
        r.r_name AS region,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM
        region r
    LEFT JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '2021-01-01'
    GROUP BY
        r.r_name
    UNION ALL
    SELECT
        'Total' AS region,
        SUM(total_sales) AS total_sales,
        SUM(customer_count) AS customer_count
    FROM
        regional_sales
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_sales DESC) AS sales_rank
FROM
    regional_sales
WHERE
    total_sales IS NOT NULL
ORDER BY
    total_sales DESC
LIMIT 10;

WITH high_value_nations AS (
    SELECT
        n.n_name,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_name
    HAVING
        AVG(s.s_acctbal) > 100000.00
)
SELECT
    h.n_name,
    h.avg_acctbal,
    COALESCE((SELECT COUNT(*) FROM customer c WHERE c.c_nationkey = n.n_nationkey), 0) AS customer_count
FROM
    high_value_nations h
LEFT JOIN
    nation n ON h.n_name = n.n_name
ORDER BY
    h.avg_acctbal DESC;
