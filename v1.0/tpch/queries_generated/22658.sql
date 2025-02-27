WITH RECURSIVE SupplierRelationship AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sr.level + 1
    FROM supplier s
    JOIN SupplierRelationship sr ON s.s_nationkey = sr.s_nationkey AND s.s_suppkey <> sr.s_suppkey
    WHERE sr.level < 5
),
PartPricing AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
           SUBSTRING(p.p_comment, 1, 10) AS comment_snippet
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_availqty > 10)
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns,
           COUNT(DISTINCT l.l_linenumber) AS total_lineitems
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT DISTINCT r.r_name, COUNT(DISTINCT sr.s_suppkey) AS supplier_count,
       AVG(pp.p_retailprice) AS avg_part_price,
       COALESCE(SUM(fo.total_returns), 0) AS total_returns,
       CASE 
           WHEN COUNT(DISTINCT sr.s_suppkey) = 0 THEN 'No suppliers'
           ELSE 'Suppliers Available'
       END AS supplier_status
FROM region r
FULL OUTER JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierRelationship sr ON n.n_nationkey = sr.s_nationkey
LEFT JOIN PartPricing pp ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sr.s_suppkey)
LEFT JOIN FilteredOrders fo ON fo.o_orderkey = sr.s_suppkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT sr.s_suppkey) > 0
   AND AVG(pp.p_retailprice) IS NOT NULL
ORDER BY r.r_name ASC NULLS LAST;
