WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 10
),
PartSupply AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, SUM(o.o_totalprice) AS customer_total
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT p.p_name, 
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
       (SELECT COUNT(*) FROM lineitem l 
        WHERE l.l_orderkey IN (SELECT o.o_orderkey 
                               FROM RecentOrders o 
                               WHERE o.o_orderdate <= l.l_shipdate)
        AND l.l_discount > 0.2) AS high_discount_count,
       AVG(CASE WHEN sh.level IS NOT NULL THEN sh.level ELSE 0 END) AS avg_sup_level,
       COALESCE(MAX(hvc.customer_total), 0) AS max_customer_total
FROM part p
LEFT JOIN PartSupply ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_partkey = s.s_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN HighValueCustomers hvc ON hvc.c_mktsegment = p.p_type
WHERE p.p_retailprice BETWEEN 15.50 AND 500.00
GROUP BY p.p_name
HAVING supplier_count > 5
ORDER BY p.p_name;
