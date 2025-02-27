WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
),
AvgPartPrices AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT p.*, COALESCE(AVG(ap.avg_supply_cost), 0) AS supplier_avg_cost
    FROM part p
    LEFT JOIN AvgPartPrices ap ON p.p_partkey = ap.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    c.c_name,
    SUM(l.l_quantity * (l.l_extendedprice - l.l_discount)) AS total_revenue,
    MAX(pd.p_retailprice) AS max_part_price,
    SUM(CASE WHEN l.l_shipdate > l.l_commitdate THEN 1 ELSE 0 END) AS late_shipments,
    COUNT(DISTINCT sh.s_suppkey) AS distinct_suppliers
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN PartDetails pd ON l.l_partkey = pd.p_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
WHERE l.l_discount BETWEEN 0.05 AND 0.15
  AND EXISTS (
      SELECT 1
      FROM partsupp ps
      WHERE ps.ps_partkey = l.l_partkey
      AND ps.ps_availqty > 0
  )
GROUP BY c.c_name
HAVING SUM(l.l_quantity) > 100
ORDER BY total_revenue DESC, c.c_name ASC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM customer WHERE c_acctbal < 100) / 2;
