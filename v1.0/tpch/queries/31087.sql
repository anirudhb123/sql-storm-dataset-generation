
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS depth
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, sh.depth + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = sh.s_suppkey LIMIT 1)
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
supplier_avg_cost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT p.p_name, 
       COALESCE(SUM(r.total_revenue), 0) AS total_order_revenue,
       AVG(sac.avg_supply_cost) AS avg_supply_cost_per_part,
       (SELECT COUNT(DISTINCT sh.s_suppkey) 
        FROM supplier_hierarchy sh 
        WHERE sh.depth <= 2) AS total_suppliers_in_hierarchy
FROM part p
LEFT JOIN ranked_orders r ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
LEFT JOIN supplier_avg_cost sac ON p.p_partkey = sac.ps_partkey
WHERE p.p_retailprice > 10.00 AND 
      (p.p_brand LIKE '%BrandY%' OR p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type = 'typeA'))
GROUP BY p.p_name
HAVING SUM(COALESCE(r.total_revenue, 0)) > 1000
ORDER BY total_order_revenue DESC;
