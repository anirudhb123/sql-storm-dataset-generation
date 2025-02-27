WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level 
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1 
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey 
    WHERE sh.level < 5 AND ps.ps_availqty > 0
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
aggregate_pricing AS (
    SELECT ps.ps_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND (CURRENT_DATE - INTERVAL '1 day')
    GROUP BY ps.ps_partkey
),
stringified_partnames AS (
    SELECT p.p_partkey,
           CONCAT(UPPER(p.p_name), ' - ', p.p_type, ' (', p.p_container, ')') AS part_description
    FROM part p
)
SELECT DISTINCT sh.s_suppkey, sh.s_name, co.c_custkey, co.c_name,
                ap.total_sales, sp.part_description, COUNT(*) OVER (PARTITION BY sh.s_suppkey) AS supply_count
FROM supplier_hierarchy sh
LEFT JOIN customer_orders co ON co.c_custkey = sh.s_nationkey
LEFT JOIN aggregate_pricing ap ON ap.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey)
LEFT JOIN stringified_partnames sp ON sp.p_partkey = (SELECT MIN(ps.ps_partkey) FROM partsupp ps 
                                                         WHERE ps.ps_suppkey = sh.s_suppkey AND ps.ps_availqty > 10)
WHERE co.order_rank = 1 
AND (sh.s_acctbal IS NOT NULL OR sh.level = 1) 
AND (sp.part_description IS NOT NULL OR sh.s_suppkey IS NULL)
ORDER BY total_sales DESC NULLS LAST;
