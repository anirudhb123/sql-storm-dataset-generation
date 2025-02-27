WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS VARCHAR(255)) AS level_name,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal,
           CONCAT(SH.level_name, ' -> ', sp.s_name) AS level_name,
           SH.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy SH ON sp.s_nationkey = SH.s_nationkey
    WHERE SH.level < 3
)

SELECT p.p_partkey, p.p_name, 
       SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       r.r_name AS region_name,
       CASE 
           WHEN SUM(li.l_quantity) IS NULL THEN 'No quantity'
           WHEN SUM(li.l_quantity) = 0 THEN 'Zero quantity'
           ELSE 'Valid quantity'
       END AS quantity_status,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(li.l_extendedprice) DESC) AS rank,
       (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_nationkey = ANY (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')) AS cust_count
FROM part p
JOIN lineitem li ON p.p_partkey = li.l_partkey
JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON li.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE li.l_returnflag = 'N'
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING SUM(li.l_extendedprice) > 10000
AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC, rank
LIMIT 10 OFFSET (SELECT COUNT(*) FROM SupplierHierarchy) / 2;

SELECT * FROM SupplierHierarchy
EXCEPT
SELECT s.s_suppkey, s.s_name, s.nationkey, s.s_acctbal
FROM supplier s
WHERE s.s_acctbal < (SELECT MIN(s_acctbal) FROM supplier);
