WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, s.s_acctbal, 
           s.s_comment, n.n_name AS nation_name, 
           r.r_name AS region_name
    FROM supplier s 
    JOIN nation n ON s.s_nationkey = n.n_nationkey 
    JOIN region r ON n.n_regionkey = r.r_regionkey
), part_info AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           p.p_type, p.p_size, p.p_container, 
           p.p_retailprice, p.p_comment
    FROM part p 
    WHERE p.p_size > 20 AND p.p_brand LIKE 'Brand%')
SELECT si.s_name, si.s_address, si.nation_name, si.region_name, 
       pi.p_name, pi.p_brand, pi.p_type, pi.p_retailprice, 
       SUM(ps.ps_availqty) AS total_available_qty, 
       AVG(ps.ps_supplycost) AS avg_supply_cost,
       COUNT(DISTINCT li.l_orderkey) AS total_orders
FROM supplier_info si 
JOIN partsupp ps ON si.s_suppkey = ps.ps_suppkey 
JOIN part_info pi ON ps.ps_partkey = pi.p_partkey 
LEFT JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
GROUP BY si.s_suppkey, si.s_name, si.s_address, si.nation_name, 
         si.region_name, pi.p_name, pi.p_brand, pi.p_type, 
         pi.p_retailprice
ORDER BY avg_supply_cost DESC, total_available_qty DESC;
