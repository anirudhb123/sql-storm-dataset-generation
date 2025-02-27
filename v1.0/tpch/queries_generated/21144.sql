WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS varchar(50)) AS hierarchy_path,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
  
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(sh.hierarchy_path, ' -> ', s.s_name) AS hierarchy_path,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),

PartStatistics AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

OrderStats AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey OR l.l_discount > 0.2
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
    GROUP BY o.o_orderkey
)

SELECT DISTINCT r.r_name,
       SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_balance,
       AVG(COALESCE(p.total_avail_qty, 0)) AS avg_avail_qty,
       SUM(COALESCE(o.total_revenue, 0)) AS total_order_revenue,
       MAX(p.avg_supply_cost) AS max_supply_cost,
       STRING_AGG(DISTINCT sh.hierarchy_path, '; ') AS supplier_hierarchy
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN PartStatistics p ON p.p_partkey IN (
    SELECT ps.p_partkey FROM partsupp ps WHERE ps.ps_availqty / NULLIF(ps.ps_supplycost, 0) > 5
)
LEFT JOIN OrderStats o ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps 
                                         WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p 
                                                                 WHERE p.p_container LIKE 'SMALL%'))
GROUP BY r.r_name
ORDER BY total_supplier_balance DESC, avg_avail_qty ASC;
