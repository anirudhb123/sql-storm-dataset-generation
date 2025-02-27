WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           CAST(c.c_custkey AS VARCHAR) AS hierarchy_path
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           CONCAT(ch.hierarchy_path, '->', c.c_custkey)
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_custkey = c.c_nationkey
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
RegionAnalysis AS (
    SELECT r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
    HAVING COUNT(n.n_nationkey) > 2
)
SELECT 
    ch.c_name AS customer_name,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_spent,
    ps.total_avail_qty,
    r.r_name AS region,
    ra.nation_count
FROM CustomerHierarchy ch
JOIN lineitem lo ON lo.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ch.c_custkey)
JOIN PartSupplierSummary ps ON ps.ps_partkey = lo.l_partkey
JOIN supplier s ON s.s_suppkey = lo.l_suppkey
JOIN nation n ON n.n_nationkey = s.s_nationkey
JOIN region r ON r.r_regionkey = n.n_regionkey
JOIN RegionAnalysis ra ON ra.r_name = r.r_name
WHERE ch.c_acctbal IS NOT NULL
GROUP BY ch.c_name, ps.total_avail_qty, r.r_name, ra.nation_count
HAVING SUM(lo.l_extendedprice) > 5000
ORDER BY total_spent DESC;
