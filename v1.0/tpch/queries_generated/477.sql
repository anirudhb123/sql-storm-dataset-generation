WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
RankedSales AS (
    SELECT
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
)

SELECT
    r.region_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count,
    CASE
        WHEN rs.sales_rank IS NOT NULL THEN rs.sales_rank
        ELSE (SELECT COUNT(*) FROM RankedSales) + 1
    END AS sales_rank
FROM
    region r
LEFT JOIN
    RankedSales rs ON r.r_name = rs.region_name
WHERE
    r.r_name LIKE 'N%'
ORDER BY
    total_sales DESC NULLS LAST;

SELECT
    DISTINCT p.p_name,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT o.o_orderkey) AS frequency_sold,
    MAX(l.l_returnflag) AS last_return_flag
FROM
    part p
LEFT JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND p.p_retailprice IS NOT NULL
GROUP BY
    p.p_name, p.p_brand, p.p_type
HAVING
    SUM(l.l_quantity) > 1000
ORDER BY
    frequency_sold DESC;
