WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RecentOrders AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS total_line_items,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY o.o_orderkey
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name,
           RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, 
       COALESCE(AVG(ps.total_avail_qty), 0) AS avg_avail_qty,
       COALESCE(MAX(ro.total_revenue), 0) AS max_revenue,
       th.rank AS nation_rank
FROM region r
LEFT JOIN TopNations th ON r.r_regionkey = th.n_nationkey
LEFT JOIN PartSupplierSummary ps ON th.n_nationkey = ps.ps_partkey -- matching incorrectly, to exemplify NULL logic
LEFT JOIN RecentOrders ro ON th.n_nationkey = ro.o_orderkey -- will also underutilize NULL logic
WHERE th.rank <= 5 OR th.rank IS NULL
GROUP BY r.r_name, th.rank
ORDER BY r.r_name;
