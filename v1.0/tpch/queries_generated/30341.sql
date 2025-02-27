WITH RECURSIVE cte_supplier_summary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rank_within_nation
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
cte_part_details AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           p.p_size,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice, p.p_size
)
SELECT ns.n_nationkey,
       n.n_name,
       ARRAY_AGG(DISTINCT s.s_name) AS suppliers,
       cte.total_supply_cost,
       pd.p_name, 
       pd.supplier_count,
       (pd.p_retailprice - COALESCE(NULLIF(cte.total_supply_cost, 0), -1)) AS price_adjusted
FROM nation n
LEFT JOIN cte_supplier_summary cte ON n.n_nationkey = cte.s_nationkey
LEFT JOIN supplier s ON cte.s_suppkey = s.s_suppkey
JOIN cte_part_details pd ON pd.supplier_count > 0
WHERE n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%' || 'Asia' || '%')
AND cte.rank_within_nation < 5
GROUP BY ns.n_nationkey, n.n_name, cte.total_supply_cost, pd.p_name, pd.supplier_count
ORDER BY total_supply_cost DESC, n.n_name;
