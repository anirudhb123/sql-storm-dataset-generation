WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS lvl
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sp.s_nationkey, sh.lvl + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal < sh.s_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS part_count, o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS active_nations,
       COALESCE(SUM(sd.total_revenue), 0) AS total_revenue,
       AVG(sd.part_count) AS avg_parts_per_order,
       MAX(s.s_acctbal) AS max_supplier_account_balance,
       CASE WHEN COUNT(DISTINCT sd.o_orderkey) > 10 THEN 'High Activity' ELSE 'Low Activity' END AS activity_level
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrderDetails sd ON sd.o_orderstatus = 'F' AND s.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_container LIKE 'SMALL%'
) 
GROUP BY r.r_name
HAVING total_revenue > 50000 OR max_supplier_account_balance IS NOT NULL
ORDER BY total_revenue DESC, active_nations ASC;
