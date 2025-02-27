WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_comment IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
      AND o.o_orderdate > CURRENT_DATE - INTERVAL '2 years'
),
PartStats AS (
    SELECT p.p_partkey, 
           COUNT(ps.ps_suppkey) AS total_suppliers,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
TopParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           ps.total_suppliers, 
           ps.avg_supplycost,
           ROW_NUMBER() OVER (ORDER BY ps.avg_supplycost DESC) AS rn
    FROM part p
    JOIN PartStats ps ON p.p_partkey = ps.p_partkey
    WHERE ps.total_suppliers IS NOT NULL OR (ps.total_suppliers IS NULL AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2))
)
SELECT 
    o.o_orderkey,
    COUNT(DISTINCT li.l_partkey) AS num_lineitems,
    SUM(CASE 
        WHEN li.l_discount > 0.1 THEN li.l_extendedprice * (1 - li.l_discount) 
        ELSE li.l_extendedprice 
    END) AS total_revenue,
    COALESCE(sh.s_name, 'No Supplier') AS supplier_name,
    tp.p_name,
    (SELECT MAX(c.c_acctbal) 
     FROM customer c 
     WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')) AS max_france_cust_acctbal
FROM FilteredOrders o
JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = li.l_suppkey
JOIN TopParts tp ON tp.p_partkey = li.l_partkey
WHERE o.o_orderkey NOT IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_orderdate < o.o_orderdate)
GROUP BY o.o_orderkey, sh.s_name, tp.p_name
HAVING SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) = 0
ORDER BY total_revenue DESC
LIMIT 10 OFFSET 5;
