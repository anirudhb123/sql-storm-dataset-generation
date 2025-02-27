
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
PartSupplierData AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost IS NOT NULL
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
),
FinalResult AS (
    SELECT r.r_regionkey, r.r_name,
           SUM(COALESCE(p.total_cost, 0)) AS total_value,
           COALESCE(AVG(co.order_count), 0) AS avg_orders_per_customer
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN PartSupplierData p ON s.s_suppkey = p.p_partkey
    LEFT JOIN CustomerOrders co ON s.s_suppkey = co.c_custkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT f.r_regionkey, f.r_name,
       f.total_value,
       f.avg_orders_per_customer,
       CASE 
           WHEN f.total_value > 1000 THEN 'High Value'
           WHEN f.total_value BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS value_category
FROM FinalResult f
ORDER BY f.total_value DESC
LIMIT 10;
