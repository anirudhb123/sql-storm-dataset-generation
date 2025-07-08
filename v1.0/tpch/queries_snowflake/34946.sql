WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= sh.s_acctbal
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
),
customer_with_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(ro.o_orderkey, 0) AS o_orderkey,
        COALESCE(ro.o_totalprice, 0) AS o_totalprice,
        ro.rank
    FROM customer c
    LEFT JOIN ranked_orders ro ON c.c_custkey = ro.o_custkey
),
part_supplier_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        p.p_retailprice,
        p.p_size,
        CASE 
            WHEN (p.p_size IS NULL OR ps.ps_supplycost IS NULL) THEN 'Unknown'
            ELSE CONCAT(p.p_name, ' (' , p.p_size , '), Cost: ', ps.ps_supplycost)
        END AS part_details
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
)
SELECT
    ch.c_name,
    sh.s_name AS supplier_name,
    po.part_details,
    po.ps_supplycost,
    SUM(ch.o_totalprice) AS total_order_value,
    COUNT(DISTINCT ch.o_orderkey) AS total_order_count
FROM customer_with_orders ch
LEFT JOIN supplier_hierarchy sh ON ch.c_custkey = sh.s_nationkey
LEFT JOIN part_supplier_data po ON sh.s_suppkey = po.p_partkey
WHERE ch.rank = 1
AND ch.o_totalprice > 1000
GROUP BY ch.c_name, sh.s_name, po.part_details, po.ps_supplycost
ORDER BY total_order_value DESC, sh.s_name
LIMIT 10 OFFSET 5;
