WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 10000 AND sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationAvg AS (
    SELECT n.n_regionkey, AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey
),
HighestSpender AS (
    SELECT c.c_custkey, c.c_name, SUM(od.total_price) AS amount_spent
    FROM customer c
    JOIN OrderDetails od ON c.c_custkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(od.total_price) > 50000
),
CombinedData AS (
    SELECT sh.level, sh.s_name, na.avg_acctbal, hs.amount_spent
    FROM SupplierHierarchy sh
    LEFT JOIN NationAvg na ON sh.s_nationkey = na.n_regionkey
    FULL OUTER JOIN HighestSpender hs ON sh.s_suppkey = hs.c_custkey
)
SELECT 
    c.level,
    c.s_name,
    COALESCE(c.avg_acctbal, 0) AS avg_acctbal,
    COALESCE(c.amount_spent, 0) AS amount_spent,
    CASE 
        WHEN c.amount_spent > 100000 THEN 'Platinum'
        WHEN c.amount_spent > 50000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier
FROM CombinedData c
WHERE c.level IS NOT NULL
ORDER BY c.amount_spent DESC, c.s_name ASC;