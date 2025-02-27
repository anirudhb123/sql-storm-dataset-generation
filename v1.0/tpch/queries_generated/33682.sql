WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal * 0.75
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
AverageParts AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueLineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           CASE 
               WHEN l.l_discount > 0.2 THEN 'High Discount' 
               ELSE 'Standard Discount' 
           END AS discount_type
    FROM lineitem l
    WHERE l.l_tax IS NOT NULL
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING c.c_acctbal IS NOT NULL
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(CASE WHEN sh.level = 0 THEN sh.s_acctbal ELSE 0 END) AS top_supplier_acctbal,
    AVG(ap.avg_supply_cost) AS average_supply_cost,
    rc.c_name,
    rc.total_spent
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN AverageParts ap ON ap.ps_partkey IN (SELECT ps_partkey FROM partsupp)
LEFT JOIN CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN RankedCustomers rc ON rc.c_custkey = co.c_custkey
GROUP BY r.r_name, rc.c_name, rc.total_spent
HAVING COUNT(DISTINCT n.n_nationkey) > 0 
   AND SUM(CASE WHEN sh.level = 0 THEN sh.s_acctbal ELSE 0 END) IS NOT NULL
ORDER BY r.r_name;
