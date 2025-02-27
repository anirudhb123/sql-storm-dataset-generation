WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
      AND o.o_orderdate >= '2023-01-01'
      AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_orderkey
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
final_results AS (
    SELECT p.p_partkey, p.p_name, n.n_name AS nation, 
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY p.p_partkey, p.p_name, n.n_name
)
SELECT f.*, 
       ns.supplier_count, 
       sh.level AS supplier_hierarchy_level, 
       os.total_revenue 
FROM final_results f
JOIN nation_stats ns ON f.nation = ns.n_name
LEFT JOIN supplier_hierarchy sh ON f.nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = sh.s_nationkey)
LEFT JOIN order_summary os ON sh.s_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.n_nationkey ORDER BY s.s_acctbal DESC LIMIT 1)
WHERE f.total_supply_cost > 1000
ORDER BY total_supply_cost DESC, rank ASC;
