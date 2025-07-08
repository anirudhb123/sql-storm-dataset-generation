
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR) AS full_name, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CONCAT(sh.full_name, ' -> ', s.s_name),
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS total_lineitems
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
RichCustomers AS (
    SELECT c.c_custkey, c.c_name, 
           COALESCE(cs.total_orders, 0) AS total_orders,
           COALESCE(cs.total_spent, 0) AS total_spent
    FROM customer c
    LEFT JOIN CustomerOrderSummary cs ON c.c_custkey = cs.c_custkey
    WHERE c.c_acctbal >= 1000
),
SupplierPerformance AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_name
)
SELECT rh.full_name, 
       COALESCE(sp.supply_value, 0) AS total_supply_value, 
       rc.total_orders, 
       rc.total_spent
FROM SupplierHierarchy rh
LEFT JOIN SupplierPerformance sp ON rh.s_name = sp.s_name
LEFT JOIN RichCustomers rc ON rc.total_spent > 5000
WHERE rh.level >= 1
ORDER BY total_supply_value DESC, rc.total_spent DESC
FETCH FIRST 100 ROWS ONLY;
