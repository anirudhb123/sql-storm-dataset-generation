WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           p.p_container,
           CASE 
               WHEN p.p_size IS NULL THEN 'Unknown Size'
               WHEN p.p_size > 50 THEN 'Large'
               WHEN p.p_size BETWEEN 21 AND 50 THEN 'Medium'
               ELSE 'Small'
           END AS size_category
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), OrderDetail AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), SupplierPartCount AS (
    SELECT ps.ps_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 1
), FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           o.o_orderdate
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
      AND o.o_orderstatus IN ('O', 'P')
)
SELECT DISTINCT r.r_name, h.p_name, h.p_retailprice, s.s_name, s.s_acctbal
FROM RankedSuppliers s
FULL OUTER JOIN HighValueParts h ON h.p_container LIKE '%' + s.s_name + '%'
JOIN region r ON s.r_regionkey = r.r_regionkey
LEFT JOIN SupplierPartCount spc ON s.s_suppkey = spc.ps_suppkey
INNER JOIN FilteredOrders fo ON fo.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey IN (
        SELECT h.p_partkey
        FROM HighValueParts h
        WHERE h.size_category = 'Large'
    )
)
WHERE s.r_regionkey IN (1, 2, 3) 
  AND (s.s_acctbal IS NOT NULL OR h.p_retailprice IS NULL)
  AND NOT EXISTS (
      SELECT 1 FROM customer c
      WHERE c.c_nationkey = s.n_nationkey
      AND c.c_acctbal < 5000.00
  )
ORDER BY r.r_name, h.p_retailprice DESC
LIMIT 100 OFFSET 10;
