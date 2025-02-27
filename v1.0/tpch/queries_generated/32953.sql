WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS varchar(255)) AS full_hierarchy
    FROM supplier s 
    WHERE s.s_acctbal >= (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(SH.full_hierarchy, ' -> ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy SH ON s.s_nationkey = SH.s_nationkey
)
SELECT C.c_name, 
       SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_revenue,
       COUNT(DISTINCT O.o_orderkey) AS total_orders,
       R.r_name AS region_name,
       ROW_NUMBER() OVER (PARTITION BY C.c_nationkey ORDER BY total_revenue DESC) AS rn
FROM customer C
JOIN orders O ON C.c_custkey = O.o_custkey
JOIN lineitem L ON O.o_orderkey = L.l_orderkey
JOIN supplier S ON L.l_suppkey = S.s_suppkey
JOIN nation N ON S.s_nationkey = N.n_nationkey
JOIN region R ON N.n_regionkey = R.r_regionkey
WHERE EXISTS (
    SELECT 1
    FROM partsupp PS
    WHERE PS.ps_partkey = L.l_partkey
      AND PS.ps_availqty > 0
)
AND L.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY C.c_custkey, C.c_name, R.r_name
HAVING SUM(L.l_extendedprice * (1 - L.l_discount)) > 10000
ORDER BY total_revenue DESC, R.r_name
LIMIT 10;
