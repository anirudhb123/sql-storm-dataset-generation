WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
RegionSupplier AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' AND o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT
    R.r_name,
    R.supplier_count,
    R.avg_acctbal,
    O.total_revenue,
    C.total_spent AS top_customer_spent,
    C.c_name AS top_customer_name,
    CASE
        WHEN R.avg_acctbal IS NULL THEN 'No Account Balance'
        ELSE 'Account Balance Present'
    END AS balance_status
FROM RegionSupplier R
LEFT JOIN OrderSummary O ON R.r_name LIKE CONCAT('%', O.o_orderkey, '%')
LEFT JOIN TopCustomers C ON R.r_name = C.c_name
ORDER BY R.supplier_count DESC, O.total_revenue DESC;
