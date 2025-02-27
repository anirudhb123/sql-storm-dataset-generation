WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.depth + 1
    FROM supplier s
    JOIN supplier_chain sc ON s.s_suppkey = sc.s_suppkey
    WHERE sc.depth < 5
),
price_analysis AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
           AVG(ps.ps_supplycost) OVER (PARTITION BY p.p_partkey) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > 10000
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING COUNT(l.l_orderkey) > 5
)
SELECT DISTINCT s.s_name, 
                s.s_acctbal, 
                p.p_name, 
                p.p_retailprice, 
                pa.avg_supplycost,
                CASE 
                    WHEN pa.price_rank = 1 THEN 'Most Expensive'
                    ELSE 'Standard'
                END AS price_category,
                oh.total_line_value
FROM supplier_chain s
LEFT JOIN price_analysis pa ON pa.p_partkey IN (
     SELECT ps.ps_partkey 
     FROM partsupp ps 
     WHERE ps.ps_supplycost <= (SELECT AVG(ps1.ps_supplycost) FROM partsupp ps1)
)
LEFT JOIN high_value_orders oh ON oh.o_totalprice > s.s_acctbal * 1.5
WHERE s.s_acctbal IS NOT NULL 
AND (s.s_acctbal / NULLIF(oh.total_line_value, 0)) > 1
ORDER BY s_name, p_retailprice DESC;
