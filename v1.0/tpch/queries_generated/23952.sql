WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal * 0.8 AND sh.level < 5
),
RegionStats AS (
    SELECT r.r_name, COUNT(s.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
),
OrderSummary AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS lineitem_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS return_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
)
SELECT r.r_name, rs.supplier_count, rs.avg_acctbal, rs.total_supply_value, 
       COALESCE(ol.lineitem_count, 0) AS lineitem_count, 
       COALESCE(ol.total_revenue, 0) AS total_revenue,
       ol.return_quantity
FROM RegionStats rs
FULL OUTER JOIN (
    SELECT o.r_name, os.lineitem_count, os.total_revenue, os.return_quantity
    FROM OrderSummary os
    JOIN (
        SELECT DISTINCT n.n_nationkey, r.r_name
        FROM region r 
        JOIN nation n ON r.r_regionkey = n.n_regionkey
    ) o ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
) ol ON rs.supplier_count >= ol.lineitem_count
ORDER BY rs.r_name, total_supply_value DESC
HAVING AVG(supplier_count) IS NOT NULL AND (return_quantity IS NULL OR return_quantity < 10)
