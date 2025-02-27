WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE sh.level < (
        SELECT COUNT(DISTINCT ps2.ps_partkey)
        FROM partsupp ps2
        WHERE ps2.ps_suppkey = s.s_suppkey
    )
),
order_details AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS total_quantity, AVG(l.l_extendedprice) AS avg_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
customer_totals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
nation_avg AS (
    SELECT n.n_nationkey, AVG(s.s_acctbal) AS avg_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
)
SELECT r.r_name, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(od.total_quantity) AS total_lineitem_quantity,
       COALESCE(MAX(ct.total_spent), 0) AS greatest_customer_spending,
       MAX(na.avg_balance) AS avg_supplier_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN order_details od ON od.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    JOIN customer_totals ct ON ct.total_spent > 1000
    WHERE o.o_custkey IS NOT NULL
)
LEFT JOIN customer_totals ct ON ct.c_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_name LIKE '%Accme%'
)
LEFT JOIN nation_avg na ON na.n_nationkey = n.n_nationkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) FILTER (WHERE sh.level > 1) > 0
   OR MAX(na.avg_balance) IS NULL
ORDER BY r.r_name DESC;
