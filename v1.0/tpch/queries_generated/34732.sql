WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
RegionStatistics AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')  -- Only completed orders
    GROUP BY c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    rh.r_name AS region_name,
    COUNT(DISTINCT cs.c_custkey) AS num_customers,
    MAX(cs.total_spent) AS max_spent,
    STRING_AGG(DISTINCT sh.s_name) AS suppliers,
    AVG(ps.total_supply_cost) AS avg_supply_cost
FROM RegionStatistics rh
JOIN CustomerOrderStats cs ON cs.total_orders > 1
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = rh.nation_count
LEFT JOIN PartSuppliers ps ON ps.p_partkey IN (SELECT p.p_partkey 
                                                  FROM part p 
                                                  WHERE p.p_retailprice > 100)
GROUP BY rh.r_name
HAVING COUNT(DISTINCT cs.c_custkey) > COALESCE(NULLIF(AVG(cs.total_spent), 0), 1)
ORDER BY num_customers DESC;
