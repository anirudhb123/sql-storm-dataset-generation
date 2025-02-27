WITH SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT
        s_suppkey,
        s_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        SupplierSales
),
HighSalesSuppliers AS (
    SELECT
        r.s_suppkey,
        r.s_name,
        r.total_sales,
        r.order_count
    FROM
        RankedSuppliers r
    WHERE
        r.sales_rank <= 10
),
CombinedResults AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(hs.total_sales, 0) AS supplier_sales,
        COALESCE(hs.order_count, 0) AS order_count,
        c.c_acctbal,
        r.r_name
    FROM
        customer c
    LEFT JOIN
        HighSalesSuppliers hs ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT
    c.c_custkey,
    c.c_name,
    c.supplier_sales,
    c.order_count,
    c.c_acctbal,
    r.r_name,
    CASE 
        WHEN c.supplier_sales > 10000 THEN 'High Sales'
        WHEN c.supplier_sales IS NULL THEN 'No Sales'
        ELSE 'Medium Sales'
    END AS sales_category
FROM
    CombinedResults c
WHERE
    c.c_acctbal IS NOT NULL
ORDER BY
    c.supplier_sales DESC, c.c_name;
