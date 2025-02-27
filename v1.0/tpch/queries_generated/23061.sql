WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn,
           CASE WHEN o.o_orderstatus = 'F' THEN 'Finalized' ELSE 'Pending' END AS status_comment
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -12, CURRENT_DATE)
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name,
           (SELECT COUNT(ps_partkey) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_count,
           MAX(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS max_acctbal,
           STRING_AGG(s.s_comment, ', ') AS all_comments
    FROM supplier s
    GROUP BY s.s_suppkey, s.s_name
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, 
           l.l_returnflag, l.l_linestatus,
           DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_rank
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.2 AND l.l_returnflag = 'N'
),
RegionAggregate AS (
    SELECT r.r_regionkey, r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(COALESCE(n.n_comment IS NOT NULL, 0)) AS comments_present
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT oh.o_orderkey, oh.o_orderstatus, oh.o_totalprice, 
       si.s_name AS supplier_name, si.part_count, 
       li.l_quantity, li.l_extendedprice, 
       ra.r_name AS region_name, ra.nation_count, ra.comments_present
FROM OrderHierarchy oh
JOIN FilteredLineItems li ON oh.o_orderkey = li.l_orderkey
JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN region r ON si.s_nationkey = r.r_regionkey
JOIN RegionAggregate ra ON ra.r_regionkey = r.r_regionkey
WHERE (oh.o_totalprice > 1000 OR si.max_acctbal = 0)
  AND (oh.rn <= 3)
  AND EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = oh.o_custkey AND c.c_mktsegment = 'BUILDING')
ORDER BY oh.o_orderdate DESC, li.l_quantity DESC, si.part_count DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
