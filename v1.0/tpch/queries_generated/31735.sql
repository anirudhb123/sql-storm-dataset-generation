WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 1000
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count, SUM(s.s_acctbal) AS total_supplier_balance
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartSupply AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
CustomerOrderInfo AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_orders_value,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ns.n_name, ns.customer_count, ns.total_supplier_balance,
       ps.p_name, ps.total_available_qty, ps.average_supply_cost,
       co.total_orders_value, co.order_count
FROM NationStats ns
FULL OUTER JOIN PartSupply ps ON ns.n_nationkey = ps.p_partkey
LEFT JOIN CustomerOrderInfo co ON ns.customer_count = co.order_count
WHERE ns.customer_count > 10
  AND (ns.total_supplier_balance IS NULL OR ns.total_supplier_balance > 5000)
ORDER BY ns.n_name, ps.p_name, co.total_orders_value DESC;
