WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_custkey <> ch.c_custkey AND c.c_acctbal > 1000
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 50.00
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS line_count, o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT ch.c_name, 
       ch.level AS customer_level, 
       n.n_name AS nation_name, 
       p.p_name AS part_name, 
       psi.total_avail_qty, 
       oi.total_revenue,
       oi.line_count,
       CASE WHEN oi.o_orderstatus = 'F' THEN 'Completed'
            ELSE 'Incomplete' END AS order_status,
       COALESCE(psi.total_supply_cost, 0) AS total_supply_cost
FROM CustomerHierarchy ch
LEFT JOIN nation n ON ch.c_nationkey = n.n_nationkey
LEFT JOIN PartSupplierInfo psi ON ch.c_custkey = psi.ps_suppkey
LEFT JOIN OrderSummary oi ON ch.c_custkey = oi.o_orderkey
WHERE ch.level < 5
ORDER BY ch.level, total_revenue DESC;
