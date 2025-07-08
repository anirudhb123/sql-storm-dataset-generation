WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
        WHERE s_nationkey IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_sales) AS total_purchases,
           RANK() OVER (ORDER BY SUM(os.total_sales) DESC) AS rank
    FROM customer c
    JOIN OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT nh.n_name, 
       COALESCE(nh.supplier_count, 0) AS supplier_count, 
       rc.total_purchases, 
       rc.rank
FROM NationSummary nh
FULL OUTER JOIN RankedCustomers rc ON nh.n_nationkey = rc.c_custkey
WHERE (rc.total_purchases IS NOT NULL OR nh.supplier_count > 0)
  AND nh.n_name LIKE 'A%'
ORDER BY nh.n_name ASC, rc.rank DESC;