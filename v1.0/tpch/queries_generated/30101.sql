WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 1 AS level
    FROM customer
    WHERE c_nationkey IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    WHERE ps.ps_supplycost > 100.00
    GROUP BY ps.ps_partkey
),
RankedRegions AS (
    SELECT r.r_name, 
           ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS region_rank
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT ch.c_name, 
       ch.level, 
       COALESCE(os.total_sales, 0) AS total_sales, 
       COALESCE(sp.total_available, 0) AS total_available_parts,
       rr.region_rank
FROM CustomerHierarchy ch
LEFT JOIN OrderSummary os ON ch.c_custkey = os.o_custkey
LEFT JOIN SupplierParts sp ON sp.ps_partkey IN (
    SELECT p.p_partkey
    FROM part p
    WHERE p.p_retailprice > 50.00
)
LEFT JOIN RankedRegions rr ON rr.region_rank = ch.level
WHERE ch.level BETWEEN 1 AND 5 AND 
      (os.total_sales IS NOT NULL OR sp.total_available IS NOT NULL)
ORDER BY ch.level, total_sales DESC;
