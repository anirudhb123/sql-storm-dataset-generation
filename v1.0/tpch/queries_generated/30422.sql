WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
avg_order_cost AS (
    SELECT o.o_orderkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_cost
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
namespace AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    s.s_acctbal, 
    o.avg_cost, 
    n.n_name, 
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'No Account Balance' 
        ELSE s.s_acctbal::text 
    END AS acctbal_status,
    COALESCE(ph.supplier_count, 0) AS nation_supplier_count,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN avg_order_cost o ON o.o_orderkey = ps.ps_partkey
JOIN namespace ph ON ph.n_name = s.s_name
JOIN ranked_orders ro ON ro.o_orderkey = ps.ps_partkey
WHERE (p.p_size > 5 AND p.p_retailprice < 100) OR (p.p_container IS NULL AND p.p_comment LIKE '%special%')
ORDER BY price_rank, o.avg_cost DESC
LIMIT 50;
