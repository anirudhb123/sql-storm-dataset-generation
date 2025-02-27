WITH RECURSIVE SuppCustomerCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM supplier s
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    WHERE c.c_acctbal < (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = s.s_nationkey)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, c.c_nationkey, c.c_custkey, c.c_name, c.c_acctbal, level + 1
    FROM supplier s
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    JOIN SuppCustomerCTE sc ON sc.s_nationkey = c.c_nationkey
    WHERE sc.level < 3
),
RegionCustomer AS (
    SELECT r.r_regionkey, r.r_name, c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_regionkey, r.r_name, c.c_custkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
),
FinalOutput AS (
    SELECT r.r_name, rc.c_custkey, rc.total_orders, pc.total_supply_cost, CASE WHEN pc.total_supply_cost IS NULL THEN 'Not Available' ELSE 'Available' END AS supply_status
    FROM RegionCustomer rc
    JOIN PartSupplier pc ON rc.total_orders > (SELECT AVG(total_orders) FROM RegionCustomer)
    JOIN region r ON rc.r_regionkey = r.r_regionkey
    JOIN RankedCustomers rc2 ON rc.c_custkey = rc2.c_custkey
    WHERE rc2.cust_rank <= 10
)
SELECT DISTINCT f.r_name, f.c_custkey, f.total_orders, f.total_supply_cost, f.supply_status
FROM FinalOutput f
WHERE f.total_orders IS NOT NULL 
  AND (f.total_supply_cost IS NULL OR f.total_supply_cost <= (SELECT AVG(total_supply_cost) FROM PartSupplier))
ORDER BY f.r_name, f.total_orders DESC;
