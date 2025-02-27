WITH RECURSIVE region_sales AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM
        region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY
        r.r_regionkey, r.r_name
    UNION ALL
    SELECT
        r.r_regionkey,
        r.r_name,
        rs.total_sales * 1.1 AS total_sales,
        rs.customer_count + 1 AS customer_count
    FROM
        region_sales rs
    JOIN region r ON rs.r_regionkey = r.r_regionkey
    WHERE
        rs.total_sales < (SELECT AVG(o.o_totalprice) FROM orders o)
)
SELECT
    r.r_name,
    COALESCE(SUM(ls.total_sales), 0) AS total_sales,
    COALESCE(SUM(ls.customer_count), 0) AS customer_count,
    CASE
        WHEN COUNT(ls.r_regionkey) = 0 THEN 'No Sales'
        ELSE 'Sales Registered'
    END AS sales_status
FROM
    region r
LEFT JOIN region_sales ls ON r.r_regionkey = ls.r_regionkey
GROUP BY
    r.r_name
ORDER BY
    total_sales DESC,
    r.r_name;
