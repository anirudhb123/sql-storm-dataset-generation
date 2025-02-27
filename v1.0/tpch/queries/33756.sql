WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level 
    FROM supplier s
    WHERE s.s_acctbal > 5000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000
),
customer_sales AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey, c.c_nationkey
),
high_value_nations AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%West%')
)
SELECT 
    p.p_name AS part_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(sh.s_name, 'Unknown Supplier') AS supplier_name,
    c.total_spent,
    cn.n_name AS nation_name
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
FULL OUTER JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN customer_sales c ON o.o_custkey = c.c_custkey
JOIN high_value_nations cn ON s.s_nationkey = cn.n_nationkey
WHERE l.l_shipdate >= DATE '1997-01-01'
GROUP BY p.p_name, sh.s_name, c.total_spent, cn.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;