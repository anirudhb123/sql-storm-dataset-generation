WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey AS suppkey, s_name, s_address, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal >= (SELECT AVG(s_acctbal) FROM supplier) 

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 

NationSize AS (
    SELECT n.n_nationkey, COUNT(DISTINCT s.s_suppkey) AS supply_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
    HAVING COUNT(DISTINCT s.s_suppkey) > 10
),

HighValueParts AS (
    SELECT p.p_partkey, p.p_name, 
           CASE 
               WHEN p.p_retailprice > 1000 THEN 'High'
               WHEN p.p_retailprice BETWEEN 500 AND 1000 THEN 'Medium'
               ELSE 'Low' 
           END AS price_category
    FROM part p
    WHERE p.p_size IS NOT NULL     
),

OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_discount) < 0.1
),

CombinedResults AS (
    SELECT dh.suppkey, dh.s_name, p.* 
    FROM SupplierHierarchy dh
    INNER JOIN HighValueParts p ON p.p_partkey IN (
        SELECT ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 20
        EXCEPT
        SELECT ps.partkey FROM partsupp ps WHERE ps.ps_supplycost < 50
    )
    WHERE EXISTS (
        SELECT 1 FROM NationSize ns WHERE dh.s_nationkey = ns.n_nationkey 
        AND ns.supply_count > 5
    )
)

SELECT DISTINCT c.c_custkey, c.c_name, 
       CASE 
           WHEN SUM(o.total_revenue) > 100000 THEN 'Top Customer'
           ELSE 'Regular Customer' 
       END AS customer_type,
       SUM(o.total_revenue) AS total_spent
FROM customer c
LEFT JOIN OrderSummary o ON c.c_custkey = o.o_orderkey
GROUP BY c.c_custkey, c.c_name
HAVING SUM(o.total_revenue) IS NOT NULL 
   AND COUNT(DISTINCT CASE WHEN o.rn = 1 THEN o.o_orderkey END) > 0
ORDER BY total_spent DESC;
