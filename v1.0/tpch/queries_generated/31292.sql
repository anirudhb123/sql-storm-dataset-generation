WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate, 1 AS hierarchy_level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT l.l_orderkey, o.o_custkey, l.l_extendedprice, l.l_shipdate, oh.hierarchy_level + 1
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN OrderHierarchy oh ON l.l_orderkey = oh.o_orderkey
    WHERE l.l_returnflag = 'N'
),
SupplierSummaries AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey
),
RegionStats AS (
    SELECT r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           AVG(s.s_acctbal) AS avg_supplier_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
RankedOrders AS (
    SELECT *, 
           RANK() OVER (PARTITION BY o_orderdate ORDER BY o_totalprice DESC) AS order_rank
    FROM orders
),
FinalOrderSummary AS (
    SELECT oh.o_orderkey,
           oh.o_custkey,
           oh.o_totalprice,
           o.order_rank,
           rs.nation_count,
           rs.avg_supplier_balance
    FROM OrderHierarchy oh
    LEFT JOIN RankedOrders o ON oh.o_orderkey = o.o_orderkey
    LEFT JOIN RegionStats rs ON rs.nation_count IS NOT NULL
    WHERE oh.hierarchy_level = 1 AND o.order_rank <= 10
)
SELECT fos.o_orderkey,
       fos.o_custkey,
       fos.o_totalprice,
       fos.order_rank,
       REPLACE(rs.r_name, 'Region', 'Area') AS region_name,
       COALESCE(fos.avg_supplier_balance, 0) AS adjusted_avg_balance
FROM FinalOrderSummary fos
JOIN RegionStats rs ON fos.nation_count > 0
ORDER BY fos.o_totalprice DESC, fos.o_orderkey ASC
LIMIT 100;
