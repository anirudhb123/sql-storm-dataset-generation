WITH RECURSIVE ranking AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY c.c_acctbal DESC) as rn
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal IS NOT NULL
),
filtered_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_retailprice IS NULL THEN 0 
               ELSE p.p_retailprice 
           END AS adjusted_price
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 5
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, s.s_acctbal, 
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
)
SELECT r.c_name, CASE 
                     WHEN total_supplycost IS NOT NULL THEN 
                         SUM(p.adjusted_price * li.l_quantity) 
                     ELSE 
                         0 
                 END AS total_revenue,
                 (SELECT COUNT(*) FROM orders o WHERE o.o_orderstatus = 'F' AND o.o_totalprice > p.adjusted_price)
FROM ranking r
JOIN lineitem li ON r.c_custkey = li.l_orderkey
JOIN filtered_parts p ON li.l_partkey = p.p_partkey
JOIN supplier_info si ON li.l_suppkey = si.s_suppkey
LEFT JOIN region rg ON si.s_suppkey = rg.r_regionkey
WHERE rg.r_name IS NULL OR rg.r_comment = ''
GROUP BY r.c_name, total_supplycost
HAVING SUM(CASE WHEN r.rn < 5 THEN p.adjusted_price ELSE 0 END) > 1000
ORDER BY total_revenue DESC
LIMIT 10
OFFSET 5;
