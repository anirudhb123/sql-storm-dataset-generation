WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000 AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500 AND sh.level < 5
),
total_order_values AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
avg_price_per_part AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
supplier_orders AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN linesitem l ON s.s_suppkey = l.l_suppkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(avg_price.avg_cost, 0) AS avg_supply_cost,
    sh.level AS supplier_hierarchy_level,
    so.order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS rank
FROM part p
LEFT JOIN avg_price_per_part avg_price ON p.p_partkey = avg_price.ps_partkey
LEFT JOIN supplier_hierarchy sh ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier_hierarchy s)
)
LEFT JOIN supplier_orders so ON so.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
WHERE p.p_size IS NOT NULL AND p.p_comment IS NOT NULL
ORDER BY p.p_name, p.p_retailprice DESC
LIMIT 100;
