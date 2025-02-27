
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal < 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_acctbal > sh.s_acctbal AND sh.level < 5
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           CASE 
               WHEN o.o_totalprice > 1000 THEN 'High'
               WHEN o.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium'
               ELSE 'Low'
           END AS price_category
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND EXTRACT(MONTH FROM o.o_orderdate) IN (1, 6)
),
customer_summary AS (
    SELECT c.c_custkey, COUNT(DISTINCT l.l_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_nationkey
)
SELECT r.r_name AS region_name, n.n_name AS nation_name, 
       SUM(l.l_extendedprice) AS total_lineitem_price,
       AVG(s.s_acctbal) AS average_supplier_balance,
       COALESCE(MAX(c.total_spent), 0) AS max_customer_spent,
       STRING_AGG(DISTINCT ps.ps_comment, '; ') AS parts_comments
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN filtered_orders fo ON fo.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderkey < 1000)
LEFT JOIN lineitem l ON l.l_orderkey = fo.o_orderkey
LEFT JOIN customer_summary c ON c.c_custkey = (SELECT c2.c_custkey 
                                                FROM customer c2 
                                                WHERE c2.c_nationkey = n.n_nationkey 
                                                ORDER BY c2.c_acctbal DESC 
                                                LIMIT 1)
WHERE r.r_name LIKE '%East%' OR (s.s_acctbal IS NULL AND n.n_comment IS NOT NULL)
GROUP BY r.r_name, n.n_name
HAVING SUM(l.l_extendedprice) > 50000 OR AVG(s.s_acctbal) IS NULL
ORDER BY region_name, nation_name;
