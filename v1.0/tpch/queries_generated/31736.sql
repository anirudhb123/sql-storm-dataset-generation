WITH RECURSIVE nation_suppliers AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal <= (SELECT AVG(s_acctbal) FROM supplier) 
      AND s.s_suppkey NOT IN (SELECT s_suppkey FROM nation_suppliers)
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_parts AS (
    SELECT p.*, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
           AVG(l.l_discount) OVER (PARTITION BY p.p_partkey) AS avg_discount
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
),
final_result AS (
    SELECT ns.n_name, ps.p_name, ps.avg_supplycost, cp.total_orders
    FROM nation_suppliers ns
    JOIN part_supplier ps ON ns.n_nationkey = ps.p_partkey
    LEFT JOIN customer_orders cp ON ns.n_nationkey = cp.c_custkey
    WHERE ps.avg_supplycost > 100.00
    ORDER BY ns.n_name, ps.p_name
)

SELECT DISTINCT fr.*, 
    CASE 
        WHEN fr.avg_supplycost IS NULL THEN 'No Cost Info'
        ELSE CAST(fr.avg_supplycost AS VARCHAR)
    END AS display_cost
FROM final_result fr
WHERE fr.total_orders IS NOT NULL 
  AND fr.total_orders > 0
UNION ALL
SELECT 'TOTAL SUPPLIERS' AS n_name, NULL, SUM(avg_supplycost) AS avg_supplycost, COUNT(*) AS total_orders
FROM final_result;
