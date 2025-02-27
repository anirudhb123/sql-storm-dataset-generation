WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_nationkey,
           CASE 
               WHEN o.o_totalprice > 10000 THEN 'High Value'
               ELSE 'Regular'
           END AS order_category
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT p.p_name, 
       COALESCE(MAX(lp.l_extendedprice), 0) AS max_extended_price,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       AVG(l.l_quantity) AS avg_quantity,
       r.region_name
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank = 1
LEFT JOIN HighValueOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN NationRegion r ON s.s_nationkey = r.n_nationkey
WHERE (p.p_brand LIKE 'Brand%') 
  AND (l.l_discount BETWEEN 0.05 AND 0.10 OR l.l_returnflag IS NULL)
  AND (s.s_acctbal IS NOT NULL OR o.o_orderkey IS NULL)
GROUP BY p.p_name, r.region_name
HAVING SUM(CASE WHEN o.order_category = 'High Value' THEN 1 ELSE 0 END) > 3
   OR COUNT(DISTINCT r.region_name) > 2
ORDER BY max_extended_price DESC, supplier_count DESC, avg_quantity ASC;
