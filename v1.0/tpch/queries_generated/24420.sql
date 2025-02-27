WITH RecursiveSales AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
TopCustomer AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(MAX(r.total_sales), 0) AS max_sales
    FROM customer c
    LEFT JOIN RecursiveSales r ON c.c_custkey = r.o_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
FilteredSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > (
        SELECT AVG(ps_supplycost) FROM partsupp
    )
),
DetailedReport AS (
    SELECT
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        SUM(Coalesce(t.total_sales, 0)) AS sales_sum
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN FilteredSuppliers s ON n.n_nationkey = s.s_suppkey
    LEFT JOIN TopCustomer t ON n.n_nationkey = t.c_custkey
    GROUP BY n.n_name, r.r_name
    HAVING SUM(COALESCE(t.max_sales, 0)) > 10000
    ORDER BY sales_sum DESC
)
SELECT 
    d.n_name,
    d.r_name,
    d.unique_suppliers,
    d.sales_sum,
    CASE 
        WHEN d.sales_sum IS NULL THEN 'Sales data missing'
        WHEN d.unique_suppliers = 0 THEN 'No suppliers available'
        ELSE 'Sales data available'
    END AS sales_status
FROM DetailedReport d
WHERE d.sales_sum >= ALL (
    SELECT DISTINCT sales_sum FROM DetailedReport
    WHERE sales_sum IS NOT NULL
)
OR d.sales_sum IS NULL
ORDER BY d.n_name;
