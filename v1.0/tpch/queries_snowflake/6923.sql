WITH RegionalSales AS (
    SELECT
        r.r_name AS region,
        SUM(o.o_totalprice) AS total_sales
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY
        r.r_name
),
TopRegions AS (
    SELECT
        region,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
)
SELECT
    tr.region,
    tr.total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value
FROM
    TopRegions tr
JOIN
    orders o ON tr.region IN (
        SELECT r.r_name
        FROM region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        WHERE o.o_orderkey = l.l_orderkey
    )
WHERE
    tr.sales_rank <= 5
GROUP BY
    tr.region, tr.total_sales
ORDER BY
    tr.total_sales DESC;
