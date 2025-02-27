
WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_type, p_container, 
           p_retailprice, p_comment, 1 AS level
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT p.p_partkey, CONCAT(ph.p_name, ' -> ', p.p_name) AS p_name, 
           p.p_brand, p.p_type, p.p_container, 
           p.p_retailprice, p.p_comment, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = p.p_partkey
    WHERE p.p_size > 0 AND ph.level < 5
), supplier_summary AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(ps.ps_partkey) AS supplied_parts,
           MAX(ps.ps_availqty) AS max_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT n.n_name, r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(o.o_totalprice) AS avg_order_value,
       SUM(su.total_supply_cost) AS total_cost,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.l_extendedprice) AS median_extended_price,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY AVG(o.o_totalprice) DESC) AS rank_per_nation
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier_summary su ON su.s_suppkey = l.l_suppkey
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 AND SUM(su.total_supply_cost) IS NOT NULL
ORDER BY n.n_name, total_cost DESC;
