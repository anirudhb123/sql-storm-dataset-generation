WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000 

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal <= sh.s_acctbal 
),

RegionAvgSupply AS (
    SELECT n.n_regionkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_regionkey
),

CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_nationkey
)

SELECT 
   r.r_name,
   AVG(COALESCE(ra.avg_supplycost, 0)) AS average_supply_cost,
   COUNT(DISTINCT ch.c_custkey) AS customer_count,
   SUM(ch.total_spent) AS total_spending
FROM region r
LEFT JOIN RegionAvgSupply ra ON r.r_regionkey = ra.n_regionkey
LEFT JOIN CustomerOrders ch ON ch.rn = 1  
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN lineitem l ON l.l_suppkey = s.s_suppkey
WHERE l.l_discount > 0.05 
GROUP BY r.r_name
HAVING COUNT(DISTINCT ch.c_custkey) > 5 
ORDER BY total_spending DESC;