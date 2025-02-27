WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.nationkey, 
           CAST(s.s_name AS VARCHAR(255)) AS path,
           1 AS level
    FROM supplier s
    WHERE s.s_nationkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.nationkey, 
           CONCAT(sh.path, ' -> ', s.s_name), 
           sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.nationkey = sh.nationkey
    WHERE sh.level < 3
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           p.p_comment, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice > 100.00
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 500.00
),
nation_region AS (
    SELECT n.n_name, r.r_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
    HAVING COUNT(s.s_suppkey) > 5
)
SELECT ns.n_name, ns.r_name, 
       COALESCE(SUM(hv.rn), 0) AS high_value_part_count,
       COALESCE(SUM(co.total_spent), 0) AS total_spent_by_customers
FROM nation_region ns
LEFT JOIN high_value_parts hv ON hv.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
    WHERE s.nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = ns.n_name)
)
LEFT JOIN customer_orders co ON co.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type = ns.r_name)
)
GROUP BY ns.n_name, ns.r_name
ORDER BY ns.n_name;
