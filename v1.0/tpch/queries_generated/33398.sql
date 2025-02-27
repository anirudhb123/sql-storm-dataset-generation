WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 3
),
TotalOrderAmounts AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
SupplierRanked AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT ch.c_name AS customer_name,
       t.total_amount AS total_order_amount,
       sr.s_name AS top_supplier,
       sr.rank AS supplier_rank
FROM CustomerHierarchy ch
LEFT JOIN TotalOrderAmounts t ON ch.c_custkey = t.o_custkey 
LEFT JOIN SupplierRanked sr ON sr.rank <= 5
WHERE ch.level = 0
  AND t.total_amount IS NOT NULL
  AND sr.s_name IS NOT NULL
ORDER BY ch.c_name, total_order_amount DESC;
