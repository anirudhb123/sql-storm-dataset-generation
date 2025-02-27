WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '2022-01-01'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_suppkey) AS supply_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
AverageOrderPrice AS (
    SELECT c.c_nationkey, AVG(o.o_totalprice) AS avg_price
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
)
SELECT r.r_name, 
       COALESCE(SUM(sd.supply_count), 0) AS total_suppliers,
       AVG(a.avg_price) AS average_order_value,
       COUNT(DISTINCT rh.s_suppkey) AS distinct_supply_level
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
LEFT JOIN SupplierHierarchy rh ON sd.s_suppkey = rh.s_suppkey
LEFT JOIN AverageOrderPrice a ON n.n_nationkey = a.c_nationkey
GROUP BY r.r_name
HAVING total_suppliers > 0
ORDER BY average_order_value DESC, r.r_name ASC;
