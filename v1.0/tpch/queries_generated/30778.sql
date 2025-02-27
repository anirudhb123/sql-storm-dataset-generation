WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), 
PartPrices AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), 
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey
),
RankedCustomer AS (
    SELECT c.c_custkey, c.c_name, co.total_orders, co.total_spent,
           RANK() OVER (ORDER BY co.total_spent DESC) AS rank_sales
    FROM customerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
)
SELECT rh.s_name, pp.p_name, pp.avg_supplycost, rc.c_name, rc.total_orders, rc.total_spent
FROM SupplierHierarchy rh
JOIN lineitem li ON li.l_suppkey = rh.s_suppkey
JOIN PartPrices pp ON li.l_partkey = pp.p_partkey
JOIN CustomerOrders co ON co.total_orders > 5
JOIN RankedCustomer rc ON rc.total_spent > 1000.00
WHERE rh.level < 3
AND COALESCE(pp.avg_supplycost, 0) > 50.00
ORDER BY rc.total_spent DESC, pp.avg_supplycost ASC;
