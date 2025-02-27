WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal,
           1 AS level
    FROM customer
    WHERE c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal,
           h.level + 1
    FROM customer c
    JOIN CustomerHierarchy h ON c.c_nationkey = h.c_nationkey
    WHERE c.c_acctbal > h.c_acctbal
),
SupplierAggregate AS (
    SELECT s.n_nationkey,
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.n_nationkey
)
SELECT r.r_name AS region,
       SUM(ch.c_acctbal) AS total_customer_balance,
       COALESCE(sa.total_suppliers, 0) AS total_suppliers,
       COALESCE(sa.total_supply_cost, 0) AS total_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerHierarchy ch ON n.n_nationkey = ch.c_nationkey
LEFT JOIN SupplierAggregate sa ON n.n_nationkey = sa.n_nationkey
GROUP BY r.r_name
HAVING SUM(ch.c_acctbal) > 500000
ORDER BY r.r_name DESC;
