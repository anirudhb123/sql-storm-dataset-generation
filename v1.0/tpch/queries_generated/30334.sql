WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 20.00
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty * ps.ps_supplycost) > 5000
),
RegionStatistics AS (
    SELECT r.r_name,
           AVG(c.total_spent) AS avg_spent,
           COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY r.r_name
)
SELECT rh.s_name AS Supplier, 
       ps.p_name AS Part, 
       co.order_count, 
       co.total_spent, 
       rs.avg_spent, 
       rs.unique_customers
FROM SupplierHierarchy rh
LEFT JOIN HighValueParts ps ON ps.total_supply_value >= 5000
JOIN CustomerOrders co ON co.rank = 1
JOIN RegionStatistics rs ON rs.avg_spent > 1000 
WHERE rh.level < 5
ORDER BY rs.avg_spent DESC, co.total_spent DESC;
