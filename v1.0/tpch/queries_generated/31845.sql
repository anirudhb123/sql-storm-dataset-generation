WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = sh.s_nationkey)
), 
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY p.p_partkey, p.p_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank,
           CASE 
               WHEN o.o_totalprice > 500 THEN 'High Value'
               WHEN o.o_totalprice BETWEEN 200 AND 500 THEN 'Mid Value'
               ELSE 'Low Value'
           END AS order_value
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT sh.s_name, ps.p_name, ps.total_available_qty, ps.avg_supply_cost, 
       o.o_orderkey, o.o_totalprice, co.order_count 
FROM SupplierHierarchy sh 
LEFT JOIN PartStats ps ON sh.s_nationkey = ps.p_partkey
LEFT JOIN OrderStats o ON o.o_orderkey = ps.p_partkey
LEFT JOIN CustomerOrderCount co ON co.c_custkey = o.o_orderkey
WHERE sh.level > 1
  AND (ps.total_available_qty IS NOT NULL OR o.o_totalprice IS NULL)
ORDER BY ps.avg_supply_cost DESC, o.o_orderkey;
