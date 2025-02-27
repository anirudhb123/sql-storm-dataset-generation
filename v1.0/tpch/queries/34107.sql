
WITH RECURSIVE SupplierTree AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS VARCHAR(100)) AS path
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal,
           CAST(CONCAT(st.path, ' -> ', sp.s_name) AS VARCHAR(100))
    FROM supplier sp
    JOIN SupplierTree st ON sp.s_nationkey = st.s_nationkey
    WHERE sp.s_acctbal IS NOT NULL
),
OrderLineStats AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS line_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
CustomerSales AS (
    SELECT c.c_custkey, SUM(ols.total_revenue) AS total_sales
    FROM customer c
    LEFT JOIN OrderLineStats ols ON c.c_custkey = ols.o_orderkey
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, cs.total_sales
    FROM customer c
    JOIN CustomerSales cs ON c.c_custkey = cs.c_custkey
    WHERE cs.total_sales > (
        SELECT AVG(total_sales)
        FROM CustomerSales
        WHERE total_sales IS NOT NULL
    )
)
SELECT p.p_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       AVG(s.s_acctbal) AS avg_supplier_balance
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN HighValueCustomers hvc ON s.s_nationkey = hvc.c_custkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
AND s.s_acctbal IS NOT NULL
GROUP BY p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY avg_supplier_balance DESC;
