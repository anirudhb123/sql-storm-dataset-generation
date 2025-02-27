WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level, CAST(s.s_name AS varchar(255)) AS path
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, CONCAT(sh.path, ' -> ', s.s_name), s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey 
    WHERE sh.level < 5
),
total_order_value AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
eligible_parts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           CASE 
               WHEN p.p_size IS NULL THEN 'UNDEFINED' 
               ELSE p.p_size::text 
           END AS size_status
    FROM part p
    WHERE EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        AND ps.ps_availqty > 50
    ) 
    AND p.p_retailprice BETWEEN 100 AND 500
),
ranked_orders AS (
    SELECT o.o_orderkey,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_discount) DESC) AS rank
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT DISTINCT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sh.path AS supplier_path,
    p.p_name AS part_name,
    CASE 
        WHEN tv.total_value > 1000 THEN 'HIGH VALUE'
        WHEN tv.total_value > 500 THEN 'MEDIUM VALUE'
        ELSE 'LOW VALUE'
    END AS order_value_category,
    size_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_suppkey
LEFT JOIN eligible_parts p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 200)
LEFT JOIN total_order_value tv ON tv.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus IN ('F', 'O')
)
LEFT JOIN ranked_orders ro ON ro.o_orderkey = tv.o_orderkey
WHERE ro.rank = 1
  AND COALESCE(sh.s_acctbal, 0) > 0
ORDER BY r.r_name, n.n_name, supplier_path, p.p_name;
