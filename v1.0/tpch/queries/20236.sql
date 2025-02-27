WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, 
           sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier sp ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_suppkey <> sh.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > 10000
),
FilteredOrders AS (
    SELECT DISTINCT o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM orders o
    WHERE o.o_totalprice IS NOT NULL AND o.o_orderdate < (cast('1998-10-01' as date) - INTERVAL '1 year')
      AND o.o_orderstatus IN ('F', 'P')
),
AggregatedLineItems AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_cost,
           AVG(l.l_tax) AS avg_tax
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
FinalResults AS (
    SELECT th.s_name AS supplier_name, fo.o_orderkey, 
           COALESCE(al.total_line_cost, 0) AS line_total, 
           SUM(fo.o_totalprice) OVER (PARTITION BY fo.o_orderkey) AS order_total,
           ROW_NUMBER() OVER (PARTITION BY fo.o_orderkey ORDER BY fo.o_totalprice DESC) AS rn
    FROM TopSuppliers th
    LEFT JOIN FilteredOrders fo ON th.s_suppkey = fo.o_orderkey
    LEFT JOIN AggregatedLineItems al ON fo.o_orderkey = al.l_orderkey
)
SELECT fr.supplier_name, fr.o_orderkey,
       CASE 
           WHEN fr.rn = 1 THEN 'Highest Total Price'
           ELSE 'Other'
       END AS ranking_label,
       fr.line_total, fr.order_total
FROM FinalResults fr
WHERE fr.line_total > (SELECT AVG(line_total) FROM FinalResults)
ORDER BY fr.order_total DESC NULLS LAST;