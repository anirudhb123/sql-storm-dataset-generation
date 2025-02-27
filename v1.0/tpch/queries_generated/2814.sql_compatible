
WITH SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM
        SupplierSales s
)
SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(rs.total_sales, 0.00) AS total_sales,
    COALESCE(rs.total_orders, 0) AS total_orders,
    CASE
        WHEN rs.sales_rank IS NULL THEN 'Not Ranked'
        ELSE CAST(rs.sales_rank AS VARCHAR)
    END AS sales_rank
FROM
    region r
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    RankedSales rs ON n.n_nationkey = (
        SELECT s.n_nationkey
        FROM supplier s
        WHERE s.s_suppkey = rs.s_suppkey
        LIMIT 1
    )
WHERE
    r.r_name LIKE 'N%'
ORDER BY
    total_sales DESC, region_name, nation_name;
