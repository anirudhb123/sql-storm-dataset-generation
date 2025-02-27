WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStatistics AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrders c
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    p.p_name,
    ps.supplier_count,
    ps.average_supply_cost,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top Customer' 
        ELSE 'Regular Customer' 
    END AS customer_status,
    sh.level
FROM region r 
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN PartSupplierStatistics ps ON ps.p_partkey = (SELECT p_partkey FROM part ORDER BY RANDOM() LIMIT 1)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = ns.n_nationkey
LEFT JOIN TopCustomers tc ON tc.c_custkey = (SELECT c_custkey FROM customer ORDER BY RANDOM() LIMIT 1)
WHERE ps.supplier_count IS NOT NULL
ORDER BY r.r_name, ns.n_name, ps.average_supply_cost DESC;
