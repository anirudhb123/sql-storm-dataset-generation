WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= 5000 AND sh.level < 2
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, COALESCE(os.total_spent, 0) AS total_spent
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)
SELECT rh.r_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
       SUM(cs.total_spent) AS total_customer_spending,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM region rh
LEFT JOIN nation n ON rh.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerSpending cs ON cs.c_custkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
WHERE rh.r_name IS NOT NULL
GROUP BY rh.r_name
HAVING SUM(cs.total_spent) > 10000 AND COUNT(DISTINCT s.s_suppkey) > 3
ORDER BY total_supply_cost DESC, total_customer_spending ASC
LIMIT 10;
