WITH SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ss.total_sales,
        ss.order_count,
        ss.avg_quantity
    FROM
        supplier s
    JOIN
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE
        ss.sales_rank <= 10
)
SELECT
    ts.s_suppkey,
    ts.s_name,
    ts.s_acctbal,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count,
    COALESCE(ts.avg_quantity, 0) AS avg_quantity,
    r.r_name AS supplier_region,
    n.n_name AS supplier_nation,
    CASE
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        WHEN ts.total_sales > 100000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM
    TopSuppliers ts
LEFT JOIN
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
LEFT JOIN
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = ps.ps_partkey LIMIT 1)))
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY
    ts.total_sales DESC, ts.s_name ASC;
