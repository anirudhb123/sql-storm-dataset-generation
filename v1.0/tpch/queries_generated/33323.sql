WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.level * 1000
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_retailprice > 100
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 3
),
nation_supplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
final_report AS (
    SELECT ch.c_custkey, ch.c_name, ch.order_count, ch.total_spent,
           nh.n_name, nh.supplier_count
    FROM customer_orders ch
    JOIN nation_supplier nh ON ch.total_spent > 1000
)
SELECT fr.c_custkey, fr.c_name, fr.order_count, fr.total_spent,
       COALESCE(fr.n_name, 'No nation') AS nation, 
       COALESCE(fr.supplier_count, 0) AS supplier_count,
       (SELECT COUNT(*) FROM high_value_parts h
        WHERE h.rn <= 5) AS top_part_count
FROM final_report fr
LEFT JOIN supplier_hierarchy sh ON fr.total_spent > sh.level * 500
ORDER BY fr.total_spent DESC, fr.order_count ASC
LIMIT 10;
