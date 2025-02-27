WITH SalesSummary AS (
    SELECT
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        COUNT(DISTINCT o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY l_partkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS sales_rank
    FROM
        lineitem
    JOIN
        orders ON l_orderkey = o_orderkey
    WHERE
        o_orderdate >= '2023-01-01'
        AND o_orderdate < DATEADD(month, 1, '2023-01-01')
    GROUP BY
        l_partkey
),
TopSales AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ss.total_sales,
        ss.order_count
    FROM
        part p
    JOIN
        SalesSummary ss ON p.p_partkey = ss.l_partkey
    WHERE
        ss.sales_rank <= 10
)
SELECT
    ts.p_partkey,
    ts.p_name,
    COALESCE(su.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(su.s_acctbal, 0) AS supplier_account_balance,
    ts.total_sales,
    ts.order_count,
    (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_partkey = ts.p_partkey) AS avg_supply_cost,
    CASE
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        WHEN ts.order_count = 0 THEN 'No Orders'
        ELSE 'Regular'
    END AS sales_status,
    ROW_NUMBER() OVER (PARTITION BY CASE WHEN ts.total_sales IS NULL THEN 1 ELSE 0 END ORDER BY ts.total_sales DESC) AS sales_category
FROM
    TopSales ts
LEFT JOIN (
    SELECT 
        ps.ps_partkey, 
        s.s_name, 
        s.s_acctbal 
    FROM 
        partsupp ps 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
) su ON ts.p_partkey = su.ps_partkey
ORDER BY
    ts.total_sales DESC,
    ts.p_name ASC;
