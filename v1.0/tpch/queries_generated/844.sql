WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
        WHERE s_nationkey = n.n_nationkey
    )
), OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
), CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, c.c_name, c.c_mktsegment
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
), RankedCustomers AS (
    SELECT c.*, RANK() OVER (PARTITION BY c_mktsegment ORDER BY c.order_count DESC) AS rank
    FROM CustomerOrders c
)
SELECT DISTINCT
    s.s_name,
    s.nation_name,
    c.c_name,
    rc.order_count,
    os.total_sales,
    CASE
        WHEN os.total_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('Total Sales: $', FORMAT(os.total_sales, 2))
    END AS sales_summary
FROM SupplierInfo s
LEFT JOIN OrderSummary os ON s.s_suppkey = os.o_custkey
JOIN RankedCustomers rc ON rc.c_custkey = os.o_custkey
WHERE rc.rank <= 5
  AND rc.order_count > 0
  AND s.s_acctbal IS NOT NULL
ORDER BY s.nation_name, os.total_sales DESC;
