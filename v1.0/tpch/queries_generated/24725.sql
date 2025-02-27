WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, 0 AS level
    FROM customer
    WHERE c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_custkey = c.c_custkey 
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
       OR ch.level < 5
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100
),
SelectedOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATEADD(month, -6, CURRENT_DATE) AND CURRENT_DATE
    GROUP BY o.o_orderkey, o.o_orderstatus
),
AggregatedResults AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(COALESCE(si.total_revenue, 0)) AS total_spent
    FROM customer c
    LEFT JOIN SelectedOrders o ON c.c_custkey = o.o_custkey
    LEFT JOIN (
        SELECT c.c_custkey, SUM(p.ps_supplycost) AS total_supplycost
        FROM customer c
        JOIN PartSupplierInfo p ON c.c_custkey = p.p_partkey
        GROUP BY c.c_custkey
    ) si ON c.c_custkey = si.c_custkey
    GROUP BY c.c_name
)
SELECT cr.c_name, ar.order_count, ar.total_spent,
       CASE 
           WHEN ar.order_count IS NULL THEN 'No Orders' 
           WHEN ar.total_spent > 10000 THEN 'High Value Customer'
           ELSE 'Standard Customer' 
       END AS customer_segment
FROM CustomerHierarchy cr
FULL OUTER JOIN AggregatedResults ar ON cr.c_name = ar.c_name
WHERE (ar.total_spent IS NOT NULL OR cr.level IS NOT NULL) 
  AND EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = cr.c_custkey)
ORDER BY cr.level, ar.total_spent DESC NULLS LAST;
