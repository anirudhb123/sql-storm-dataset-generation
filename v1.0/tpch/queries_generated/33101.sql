WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), 
size_summary AS (
    SELECT p_size, COUNT(*) AS part_count, AVG(p_retailprice) AS avg_price
    FROM part
    GROUP BY p_size
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 500
    GROUP BY c.c_custkey, c.c_name
), 
supplier_part_summary AS (
    SELECT ps.ps_supkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
)
SELECT 
    c.c_name AS customer_name,
    sh.s_name AS supplier_name,
    sz.p_size AS part_size,
    sz.avg_price AS average_price,
    COALESCE(c.total_spent, 0) AS customer_total_spent,
    sp.total_available AS supplier_total_available,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY c.total_spent DESC) AS rank
FROM customer_orders c
FULL OUTER JOIN supplier_hierarchy sh ON sh.s_nationkey = c.c_nationkey
JOIN size_summary sz ON sz.part_count > 10
LEFT JOIN supplier_part_summary sp ON sp.ps_supkey = sh.s_suppkey
WHERE (c.c_custkey IS NOT NULL OR sh.s_suppkey IS NOT NULL)
  AND (c.total_spent > 1000 OR sp.total_available IS NULL)
ORDER BY customer_name, supplier_name, part_size;
