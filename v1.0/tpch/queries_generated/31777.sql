WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty < 50
),
average_order_value AS (
    SELECT o.o_custkey, AVG(o.o_totalprice) AS avg_totalprice
    FROM orders o
    GROUP BY o.o_custkey
),
nation_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(sh.level, -1) AS supplier_level,
    n.n_name AS nation_name,
    avg.avg_totalprice,
    n_sum.supplier_count,
    (CASE 
        WHEN p.p_retailprice > 100 THEN 'High Value'
        ELSE 'Low Value'
     END) AS value_category
FROM part p
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_name = 'EUROPE'
)
JOIN average_order_value avg ON avg.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_acctbal > 500
)
JOIN nation_summary n_sum ON n_sum.nation_count > 5
CROSS JOIN nation n 
WHERE n.n_regionkey = (
    SELECT r.r_regionkey 
    FROM region r 
    WHERE r.r_name = 'ASIA'
)
ORDER BY p.p_partkey
FETCH FIRST 100 ROWS ONLY;
