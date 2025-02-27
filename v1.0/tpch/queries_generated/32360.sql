WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AggLineItems AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY l.l_partkey
),
TopProducts AS (
    SELECT p.p_partkey, p.p_name, AL.total_revenue,
           ROW_NUMBER() OVER (ORDER BY AL.total_revenue DESC) AS rn
    FROM part p
    JOIN AggLineItems AL ON p.p_partkey = AL.l_partkey
)
SELECT N.n_name, COUNT(DISTINCT C.c_custkey) AS customer_count, 
       SUM(CASE WHEN O.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS completed_orders,
       COALESCE(AVG(S.s_acctbal), 0) AS avg_supplier_balance
FROM nation N
LEFT JOIN supplier S ON N.n_nationkey = S.s_nationkey
LEFT JOIN customer C ON N.n_nationkey = C.c_nationkey
LEFT JOIN orders O ON C.c_custkey = O.o_custkey
JOIN TopProducts TP ON TP.p_partkey IN (SELECT ps_partkey FROM partsupp PS WHERE PS.ps_suppkey = S.s_suppkey)
GROUP BY N.n_name
HAVING COUNT(DISTINCT C.c_custkey) > 10
ORDER BY customer_count DESC
LIMIT 10;
