WITH RECURSIVE supplier_hierarchy(s_suppkey, s_name, s_nationkey, level) AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, n.n_comment, sh.s_suppkey, sh.s_name
    FROM nation n
    LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
), part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) as rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
), average_price AS (
    SELECT AVG(p.p_retailprice) as avg_retailprice
    FROM part p
), customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ns.n_name, 
       COUNT(DISTINCT ns.s_suppkey) as total_suppliers,
       SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_qty,
       COUNT(DISTINCT co.c_custkey) as total_customers,
       CASE WHEN AVG(ps.ps_supplycost) IS NULL THEN NULL ELSE ROUND(AVG(ps.ps_supplycost), 2) END as avg_supply_cost,
       MAX(CASE WHEN ns.n_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_comment LIKE '%special%') 
                THEN 1 ELSE 0 END) AS special_nation_indicator
FROM nation_supplier ns
FULL OUTER JOIN part_supplier ps ON ns.n_nationkey = ps.p_partkey
LEFT JOIN customer_orders co ON ns.s_suppkey = co.c_custkey
WHERE ns.n_name IS NOT NULL 
  AND (ps.ps_supplycost < (SELECT avg_retailprice FROM average_price) OR ps.ps_supplycost IS NULL)
GROUP BY ns.n_name
HAVING COUNT(DISTINCT ns.s_suppkey) > 0
ORDER BY 1;
