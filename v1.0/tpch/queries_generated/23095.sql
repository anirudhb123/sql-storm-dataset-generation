WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, c.level + 1
    FROM supplier s
    JOIN SupplierCTE c ON s.s_nationkey = c.s_nationkey
    WHERE s.s_acctbal > c.s_acctbal AND c.level < 3
),
PartOrderDetails AS (
    SELECT p.p_partkey, p.p_name, l.l_orderkey, o.o_totalprice, l.l_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
),
SizeBasedRanks AS (
    SELECT p.p_partkey, p.p_name, RANK() OVER (PARTITION BY p.p_size ORDER BY SUM(l.l_extendedprice) DESC) AS size_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_size
)
SELECT COALESCE(s.s_name, 'Unknown') AS Supplier_Name,
       pp.p_name AS Part_Name,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
       CASE 
           WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Volume'
           ELSE 'Low Volume'
       END AS Order_Volume_Classification,
       STRING_AGG(DISTINCT r.r_name, ', ') AS Regions_Supplied
FROM SupplierCTE s
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN PartOrderDetails pp ON ps.ps_partkey = pp.p_partkey
LEFT JOIN region r ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN lineitem l ON pp.l_orderkey = l.l_orderkey
JOIN SizeBasedRanks sr ON pp.p_partkey = sr.p_partkey
WHERE sr.size_rank = 1
  AND l.l_returnflag = 'N'
  AND pp.o_totalprice IS NOT NULL
GROUP BY s.s_name, pp.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY Revenue DESC
LIMIT 50 OFFSET 10;
