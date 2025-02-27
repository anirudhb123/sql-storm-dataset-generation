
WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
FilteredOrders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
PivotedSales AS (
    SELECT o.o_orderkey,
           SUM(CASE WHEN o.o_orderstatus = 'F' THEN total_sales ELSE 0 END) AS finalized_sales,
           SUM(CASE WHEN o.o_orderstatus = 'P' THEN total_sales ELSE 0 END) AS pending_sales
    FROM FilteredOrders o
    GROUP BY o.o_orderkey
),
RegionSales AS (
    SELECT n.n_name AS nation_name,
           SUM(p.total_sales) AS total_revenue,
           AVG(p.part_count) AS avg_parts_per_order
    FROM nation n
    JOIN FilteredOrders p ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = p.o_custkey)
    GROUP BY n.n_name
),
SupplierComments AS (
    SELECT DISTINCT s.s_comment,
           SUBSTRING(s.s_comment FROM POSITION('@' IN s.s_comment) FOR 5) AS obscured_comment
    FROM supplier s
    WHERE s.s_comment IS NOT NULL
)
SELECT r.r_name,
       COALESCE(rs.total_revenue, 0) AS total_revenue,
       COALESCE(ps.finalized_sales, 0) AS finalized_sales,
       COALESCE(ps.pending_sales, 0) AS pending_sales,
       s.s_name,
       s.s_acctbal,
       STRING_AGG(DISTINCT sc.obscured_comment, ',') AS aggregated_comments
FROM region r
LEFT JOIN RegionSales rs ON r.r_regionkey = (
    SELECT n.n_regionkey 
    FROM nation n 
    WHERE n.n_name LIKE '%e%'
    LIMIT 1
)
LEFT JOIN PivotedSales ps ON ps.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'P') AND o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2
        WHERE o2.o_orderstatus = 'F'
    )
)
JOIN RankedSuppliers s ON s.rank = 1
LEFT JOIN SupplierComments sc ON s.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_brand LIKE '%BrandX%'
    LIMIT 1
)
GROUP BY r.r_name, rs.total_revenue, ps.finalized_sales, ps.pending_sales, s.s_name, s.s_acctbal
ORDER BY total_revenue DESC, s.s_acctbal DESC
