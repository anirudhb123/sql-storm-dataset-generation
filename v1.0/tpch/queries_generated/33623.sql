WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
OrderStats AS (
    SELECT c.c_name, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_name
),
PartSupplies AS (
    SELECT p.p_partkey, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT R.r_name AS region, 
       N.n_name AS nation,
       S.s_name AS supplier_name,
       P.p_name AS part_name,
       PS.total_available, 
       OS.total_spent,
       OS.order_count,
       PS.avg_supply_cost,
       RANK() OVER (PARTITION BY R.r_name ORDER BY OS.total_spent DESC) AS rank_within_region
FROM region R
JOIN nation N ON R.r_regionkey = N.n_regionkey
LEFT JOIN SupplierHierarchy SH ON N.n_nationkey = SH.s_nationkey
FULL OUTER JOIN lineitem L ON L.l_suppkey = SH.s_suppkey
JOIN PartSupplies PS ON L.l_partkey = PS.p_partkey
JOIN OrderStats OS ON OS.order_count > 10
WHERE COALESCE(PS.total_available, 0) > 0
  AND SH.level <= 3
ORDER BY region, total_spent DESC, supplier_name;
