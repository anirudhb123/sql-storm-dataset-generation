WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE c.c_acctbal > ch.c_acctbal
),
MaxOrderCost AS (
    SELECT o.o_custkey, MAX(o.o_totalprice) AS max_order_cost
    FROM orders o
    GROUP BY o.o_custkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, s.s_name, ps.ps_supplycost, ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS total_lines,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT ch.c_name, ch.c_acctbal, m.max_order_cost, 
       CONCAT('Customer Level: ', ch.level) AS customer_level,
       COALESCE(p.p_name, 'No Available Parts') AS part_name, 
       COALESCE(ps.ps_availqty, 0) AS available_quantity,
       lis.total_revenue
FROM CustomerHierarchy ch
LEFT JOIN MaxOrderCost m ON ch.c_custkey = m.o_custkey
LEFT JOIN LineItemSummary lis ON ch.c_custkey = lis.l_orderkey
LEFT JOIN PartSupplierInfo ps ON ps.ps_supplycost = (SELECT MIN(ps_supplycost) FROM PartSupplierInfo) 
LEFT JOIN part p ON ps.p_partkey = p.p_partkey
WHERE ch.c_acctbal > 15000 
  AND (m.max_order_cost IS NULL OR m.max_order_cost > 5000)
ORDER BY ch.c_acctbal DESC, total_revenue DESC;
