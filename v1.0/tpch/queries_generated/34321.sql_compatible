
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh_parent.level + 1
    FROM orders oh
    JOIN OrderHierarchy oh_parent ON oh.o_orderkey = oh_parent.o_orderkey
    WHERE oh.o_orderstatus <> 'O'
),
SupplierSales AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY s.s_suppkey
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count, SUM(ss.total_sales) AS total_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN SupplierSales ss ON ss.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
    GROUP BY r.r_name
)
SELECT rh.o_orderkey, rh.o_orderdate, rh.o_totalprice, 
       COALESCE(rs.nation_count, 0) AS nation_count, 
       COALESCE(rs.total_sales, 0.00) AS total_sales,
       RANK() OVER (PARTITION BY rh.o_orderkey ORDER BY rh.o_totalprice DESC) AS order_rank
FROM OrderHierarchy rh
LEFT JOIN RegionStats rs ON EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = rh.o_orderkey)
WHERE rh.o_totalprice > 1000 
AND (rs.total_sales IS NOT NULL OR rs.nation_count > 0)
ORDER BY rh.o_orderdate DESC, order_rank;
