WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal >= sh.s_acctbal * 0.9
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
AggregatedData AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.total_supply_cost,
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS rank_retail,
           ROW_NUMBER() OVER (ORDER BY ps.total_supply_cost ASC) AS rank_supply
    FROM part p
    LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
)
SELECT r.r_name, n.n_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       COUNT(DISTINCT tc.c_custkey) AS customer_count,
       AVG(ad.p_retailprice) AS average_retail_price,
       AVG(ad.total_supply_cost) AS average_supply_cost
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN TopCustomers tc ON tc.total_spent > (SELECT AVG(total_spent) FROM TopCustomers) 
LEFT JOIN AggregatedData ad ON ad.rank_retail <= 10 AND ad.rank_supply <= 10
GROUP BY r.r_name, n.n_name
HAVING AVG(ad.p_retailprice) IS NOT NULL AND COUNT(DISTINCT tc.c_custkey) > 5
ORDER BY supplier_count DESC, customer_count DESC;
