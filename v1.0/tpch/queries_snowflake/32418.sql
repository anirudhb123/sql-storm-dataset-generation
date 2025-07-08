WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS level 
    FROM supplier s 
    WHERE s.s_name LIKE 'Supplier%' 
    UNION ALL 
    SELECT s.s_suppkey, s.s_name, sh.level + 1 
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey + 1
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent 
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey, c.c_name 
), 
lineitem_summary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(*) AS item_count
    FROM lineitem l 
    GROUP BY l.l_orderkey
),
part_supplier AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost 
    FROM part p 
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY p.p_partkey, p.p_name
),
region_summary AS (
    SELECT r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count 
    FROM region r 
    JOIN nation n ON r.r_regionkey = n.n_regionkey 
    GROUP BY r.r_name
)
SELECT ps.p_name, 
       ps.total_available, 
       ps.avg_supply_cost, 
       cbo.total_spent AS customer_spending,
       rs.nation_count, 
       ROW_NUMBER() OVER (PARTITION BY rs.nation_count ORDER BY ps.avg_supply_cost DESC) AS rank 
FROM part_supplier ps 
LEFT JOIN customer_orders cbo ON ps.p_partkey = cbo.c_custkey 
LEFT JOIN region_summary rs ON rs.nation_count > 0 
WHERE ps.total_available IS NOT NULL 
  AND rs.nation_count > 1 
ORDER BY ps.avg_supply_cost ASC;
