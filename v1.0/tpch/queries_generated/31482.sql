WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')    
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierStats AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
)
SELECT 
    ch.c_custkey,
    ch.c_name,
    ns.n_name AS nation,
    SUM(ts.total_sales) AS total_sales,
    ss.part_count,
    ss.avg_supplycost,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.rank_order
FROM CustomerHierarchy ch
LEFT JOIN nation ns ON ch.c_nationkey = ns.n_nationkey
LEFT JOIN TotalSales ts ON ts.l_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_partkey = ch.c_custkey) 
LEFT JOIN SupplierStats ss ON ss.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = ss.s_suppkey))
LEFT JOIN RankedOrders ro ON ro.o_orderkey = ts.l_orderkey
WHERE ro.o_orderstatus IN ('F', 'O') AND ro.rank_order <= 10
GROUP BY ch.c_custkey, ch.c_name, ns.n_name, ss.part_count, ss.avg_supplycost, ro.o_orderdate, ro.o_totalprice, ro.rank_order
ORDER BY total_sales DESC, ch.c_name ASC;
