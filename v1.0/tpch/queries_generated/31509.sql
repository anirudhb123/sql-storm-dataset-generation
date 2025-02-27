WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
ProductStatistics AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost, 
           (SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) 
            FROM lineitem l 
            WHERE l.l_partkey = p.p_partkey) AS total_revenue
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name,
           ROW_NUMBER() OVER(PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
FilteredNations AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    WHERE EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = n.n_nationkey AND s.s_acctbal > 5000)
)
SELECT ps.p_partkey, ps.avg_supply_cost, ps.supplier_count, cs.rank,
       CASE 
           WHEN ps.total_revenue IS NULL THEN 0 
           ELSE ps.total_revenue 
       END AS total_revenue_adjusted,
       rn.r_name
FROM ProductStatistics ps
LEFT JOIN FilteredNations fn ON fn.n_nationkey = ps.p_partkey
LEFT JOIN Region rn ON fn.n_nationkey = rn.r_regionkey
JOIN CustomerStats cs ON cs.c_custkey = ps.supplier_count
WHERE ps.avg_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY total_revenue_adjusted DESC
LIMIT 10;
