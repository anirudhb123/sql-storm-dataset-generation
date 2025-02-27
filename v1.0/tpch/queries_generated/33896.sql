WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal < 1000 -- Starting point for suppliers with low account balance
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE sh.level < 3 -- Limit recursion to 3 levels deep
),
AggregatedSales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
HighValueCustomers AS (
    SELECT cust.c_custkey, cust.c_name, cust.total_sales, cust.order_count, r.r_name
    FROM AggregatedSales cust
    JOIN nation n ON cust.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE cust.total_sales > 5000 AND cust.order_count > 10
)
SELECT
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_balance,
    hv_cust.c_name AS high_value_customer,
    hv_cust.total_sales AS customer_sales,
    hv_cust.order_count AS customer_orders,
    r.r_name AS region_name,
    COALESCE(ROW_NUMBER() OVER (PARTITION BY hv_cust.r_name ORDER BY s.s_acctbal DESC), 0) AS supplier_rank
FROM SupplierHierarchy s
FULL OUTER JOIN HighValueCustomers hv_cust ON s.n_nationkey = hv_cust.n_nationkey
JOIN nation n ON hv_cust.n_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE (s.s_acctbal IS NOT NULL OR hv_cust.total_sales IS NOT NULL)
  AND (s.s_acctbal IS NULL OR hv_cust.total_sales IS NULL OR hv_cust.total_sales > 10000)
ORDER BY r.r_name, supplier_rank DESC;
