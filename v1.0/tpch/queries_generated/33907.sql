WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), 
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
), 
RegionStats AS (
    SELECT r.r_regionkey, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
)
SELECT 
    sh.s_name AS supplier_name,
    os.total_sales AS sales_total,
    p.p_name AS part_name,
    COALESCE(rns.nation_count, 0) AS region_nation_count,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'Price Not Available'
        ELSE CONCAT('Price: $', ROUND(p.p_retailprice, 2))
    END AS price_details
FROM SupplierHierarchy sh
JOIN OrderSummary os ON sh.s_suppkey = os.o_orderkey
JOIN RankedParts p ON sh.s_nationkey = p.p_partkey
LEFT JOIN RegionStats rns ON rns.r_regionkey = sh.s_nationkey
WHERE os.total_sales > 1000
  AND p.price_rank <= 10
ORDER BY os.total_sales DESC, p.p_retailprice ASC;
