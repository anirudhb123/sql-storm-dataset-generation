WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level 
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal * 1.1, sh.level + 1 
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 
part_supplier_summary AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
), 
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           AVG(s.s_acctbal) AS avg_acctbal,
           MAX(s.s_acctbal) AS max_acctbal, 
           MIN(s.s_acctbal) AS min_acctbal 
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name 
), 
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
           CASE 
               WHEN o.o_orderstatus = 'O' THEN 'Open Order'
               ELSE 'Closed Order'
           END AS order_type
    FROM orders o
)
SELECT ps.p_partkey, ps.p_name, ns.n_name AS supplier_nation, 
       ps.total_supply_cost, ns.avg_acctbal AS avg_supplier_acctbal,
       os.o_totalprice, os.order_type,
       CASE 
           WHEN os.price_rank = 1 THEN 'Highest Price'
           WHEN os.price_rank = 2 THEN 'Second Highest Price'
           ELSE 'Other Price'
       END AS price_category
FROM part_supplier_summary ps
JOIN nation_stats ns ON ps.unique_suppliers > ns.total_suppliers 
LEFT JOIN order_summary os ON ps.p_partkey = os.o_orderkey OR os.o_orderkey IS NULL
WHERE ps.total_supply_cost IS NOT NULL 
AND (ps.total_supply_cost - COALESCE(NULLIF(ns.avg_acctbal, 0), NULL)) > 1000
ORDER BY ps.total_supply_cost DESC, ns.avg_acctbal ASC;
