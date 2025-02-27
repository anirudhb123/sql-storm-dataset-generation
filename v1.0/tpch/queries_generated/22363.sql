WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
region_details AS (
    SELECT r.r_regionkey, r.r_name, 
           (SELECT COUNT(DISTINCT n.n_nationkey)
            FROM nation n
            WHERE n.n_regionkey = r.r_regionkey) AS nation_count
    FROM region r
)
SELECT n.n_name, 
       COALESCE(MAX(sd.total_supply_cost), 0) AS max_supply_cost,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS return_sales,
       COUNT(DISTINCT c.c_custkey) AS distinct_customers,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_quantity) DESC) AS rank_by_quantity
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier_details sd ON n.n_nationkey = sd.s_suppkey
JOIN lineitem l ON l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN customer c ON c.c_nationkey = n.n_nationkey
WHERE sd.part_count > (
      SELECT AVG(part_count) FROM supplier_details
)
GROUP BY n.n_name, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
   OR MAX(sd.total_supply_cost) IS NULL
ORDER BY rank_by_quantity DESC, max_supply_cost ASC;
