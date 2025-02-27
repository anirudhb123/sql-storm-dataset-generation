WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
customer_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, 
           COUNT(o.o_orderkey) AS order_count, 
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name, 
    p.p_brand, 
    MAX(dp.max_discount) AS max_discount,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    CASE 
        WHEN MAX(cust.total_spent) IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY total_revenue DESC) as revenue_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN (
    SELECT l.l_partkey, MAX(l.l_discount) AS max_discount
    FROM lineitem l
    GROUP BY l.l_partkey
) dp ON p.p_partkey = dp.l_partkey
LEFT JOIN customer_summary cust ON cust.c_custkey IN (
    SELECT DISTINCT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
)
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
GROUP BY p.p_name, p.p_brand
HAVING SUM(COALESCE(l.l_quantity, 0)) > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_shipmode = 'AIR')
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
