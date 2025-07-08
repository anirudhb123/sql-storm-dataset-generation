WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
      AND sh.level < 3
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_suppkey, ps.ps_availqty, 
           ps.ps_supplycost * ps.ps_availqty AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT l.l_orderkey, COUNT(*) AS lineitem_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT n.n_name, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(ps.total_supply_cost) AS total_supply_cost,
       SUM(co.total_order_value) AS total_customer_orders,
       AVG(ls.total_revenue) AS avg_lineitem_revenue,
       MAX(CASE WHEN ls.return_count > 0 THEN ls.lineitem_count END) AS max_returned_lineitems
FROM nation n
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN part_supplier ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN customer_orders co ON n.n_nationkey = co.c_custkey
INNER JOIN lineitem_summary ls ON co.c_custkey = ls.l_orderkey
WHERE n.n_name LIKE 'A%' OR n.n_name IS NULL
GROUP BY n.n_name
ORDER BY total_supply_cost DESC, avg_lineitem_revenue DESC
LIMIT 10;
