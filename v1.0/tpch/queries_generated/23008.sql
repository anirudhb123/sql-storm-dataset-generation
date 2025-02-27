WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s2.s_suppkey, 
           s2.s_name, 
           s2.s_acctbal,
           sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s2 ON ps.ps_suppkey = s2.s_suppkey
    WHERE sh.level < 10
),
nation_stats AS (
    SELECT n.n_nationkey, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal,
           MAX(s.s_acctbal) AS max_acctbal,
           SUM(CASE WHEN s.s_acctbal > 5000 THEN 1 ELSE 0 END) AS high_balance_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
),
part_region AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count_in_region,
           SUM(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_availqty ELSE 0 END) AS total_avail_qty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY p.p_partkey, p.p_name
),
order_details AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value_after_discount,
           o.o_orderdate,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Finished' 
               ELSE 'Pending' 
           END AS order_status
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT p.p_partkey, 
       p.p_name, 
       pr.supplier_count_in_region,
       ns.supplier_count AS total_supplier_count,
       ns.high_balance_count,
       ns.avg_acctbal,
       od.total_value_after_discount,
       ROW_NUMBER() OVER (PARTITION BY pr.supplier_count_in_region ORDER BY pr.total_avail_qty DESC) AS region_rank,
       sh.level AS supplier_level
FROM part p
JOIN part_region pr ON p.p_partkey = pr.p_partkey
JOIN nation_stats ns ON 1=1
JOIN order_details od ON od.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o 
                                           WHERE o.o_orderkey > 0 AND 
                                                 o.o_orderkey IS NOT NULL)
LEFT JOIN supplier_hierarchy sh ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey)
WHERE pr.supplier_count_in_region > 0 
AND (ns.avg_acctbal IS NOT NULL OR ns.max_acctbal IS NOT NULL)
ORDER BY sh.level, ns.avg_acctbal DESC;
