WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_comment IS NOT NULL
    WHERE sh.level < 5
),
RegionSupplier AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    GROUP BY r.r_regionkey, r.r_name
),
ExpensiveParts AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, p.p_brand, ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY o.o_totalprice DESC) AS ranking
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE o.o_orderstatus IN ('O', 'F')
      AND p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT r.r_name, rs.supplier_count, COUNT(DISTINCT fo.o_orderkey) AS high_value_order_count,
       MAX(fo.o_totalprice) AS highest_order_value,
       COUNT(DISTINCT CASE WHEN fo.ranking = 1 THEN fo.o_orderkey END) AS top_brand_orders,
       STRING_AGG(DISTINCT p.p_mfgr, ', ') FILTER (WHERE fo.ranking <= 5) AS top_manufacturers
FROM RegionSupplier rs
JOIN FilteredOrders fo ON rs.supplier_count > 10
LEFT JOIN part p ON fo.p_brand = p.p_brand
GROUP BY r.r_name, rs.supplier_count
HAVING SUM(fo.o_totalprice) IS NOT NULL
ORDER BY r.r_name, rs.supplier_count DESC;
