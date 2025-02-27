WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_name LIKE 'Supplier%'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier_chain sc
    JOIN partsupp ps ON sc.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE level < 3
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey
),
product_info AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
top_products AS (
    SELECT p.p_partkey, p.p_name, pi.total_available,
           ROW_NUMBER() OVER (ORDER BY pi.total_available DESC) AS rank
    FROM part p
    JOIN product_info pi ON p.p_partkey = pi.p_partkey
    WHERE p.p_retailprice IS NOT NULL AND p.p_retailprice > 100.00
    HAVING total_available > 0
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(o.total_sales) AS total_sales,
       AVG(s.s_acctbal) AS avg_supplier_balance,
       STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN order_summary o ON s.s_suppkey = o.o_orderkey
LEFT JOIN top_products p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_sales DESC
LIMIT 10;
