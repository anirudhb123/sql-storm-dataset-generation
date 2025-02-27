WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, sh.s_nationkey, s.s_acctbal + sh.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_suppkey, ps.ps_availqty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_suppkey, ps.ps_availqty
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT n.n_name, 
       SUM(p.supply_value) AS total_supply_value,
       COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
       MAX(cs.order_count) AS max_orders_per_customer,
       COALESCE(AVG(cs.total_spent), 0) AS avg_spent_per_customer
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN PartSupplierInfo p ON sh.s_suppkey = p.ps_suppkey
LEFT JOIN CustomerSummary cs ON n.n_nationkey = (SELECT n2.n_regionkey FROM nation n2 WHERE n2.n_nationkey = cs.c_custkey)
WHERE p.ps_availqty IS NOT NULL
GROUP BY n.n_name
HAVING SUM(p.total_supply_cost) > 10000
ORDER BY total_supply_value DESC
LIMIT 10;
