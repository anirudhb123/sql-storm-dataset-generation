WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
RankedPartSupp AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM partsupp ps
    WHERE ps.ps_availqty > 100
),
TopRegions AS (
    SELECT r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
    HAVING COUNT(n.n_nationkey) > 1
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE)
)
SELECT p.p_partkey, p.p_name, p.p_brand, region_info.r_name AS region, 
       COALESCE(supp_hierarchy.s_name, 'Unknown Supplier') AS supplier_name,
       p_sum.total_price,
       (p.p_retailprice * 0.9) AS discounted_price,
       CASE WHEN p_sum.total_price IS NULL THEN 'No orders' ELSE 'Has orders' END AS order_status
FROM part p
LEFT JOIN (
    SELECT l.l_partkey, SUM(l.l_extendedprice) AS total_price
    FROM lineitem l
    JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
    GROUP BY l.l_partkey
) p_sum ON p.p_partkey = p_sum.l_partkey
LEFT JOIN TopRegions region_info ON p.p_partkey % 5 = region_info.nation_count
LEFT JOIN SupplierHierarchy supp_hierarchy ON supp_hierarchy.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM RankedPartSupp ps 
    WHERE ps.ps_partkey = p.p_partkey AND ps.supply_rank = 1
)
WHERE p.p_size BETWEEN 10 AND 20
  AND (p.p_comment IS NULL OR p.p_comment LIKE '%unique%')
ORDER BY p.p_partkey, discounted_price DESC;
