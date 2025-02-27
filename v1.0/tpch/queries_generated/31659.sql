WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
total_orders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
part_supplier_info AS (
    SELECT p.p_brand, ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY p.p_brand, ps.ps_partkey
),
ranked_part_supplier AS (
    SELECT p.p_brand, p.ps_partkey, total_available,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY total_available DESC) AS rnk
    FROM part_supplier_info p
    WHERE total_available > 100
),
final_output AS (
    SELECT c.c_name, c.c_acctbal, o.o_orderstatus, o.o_orderdate,
           COALESCE(rp.p_brand, 'No Brand') AS preferred_brand,
           COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN ranked_part_supplier rp ON rp.ps_partkey = (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey
        ORDER BY l.l_extendedprice DESC
        LIMIT 1
    )
    LEFT JOIN supplier s ON s.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = rp.ps_partkey
        ORDER BY ps.ps_supplycost
        LIMIT 1
    )
    WHERE c.c_acctbal IS NOT NULL
)
SELECT f.c_name, f.total_spent, f.o_orderdate, f.preferred_brand, f.supplier_name,
       CASE 
           WHEN f.o_orderstatus = 'F' THEN 'Completed'
           WHEN f.o_orderstatus = 'P' THEN 'Pending'
           ELSE 'Unknown Status'
       END AS order_status_description
FROM final_output f
JOIN total_orders t ON f.o_custkey = t.o_custkey
ORDER BY f.total_spent DESC, f.o_orderdate DESC
LIMIT 100;
