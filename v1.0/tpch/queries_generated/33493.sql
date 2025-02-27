WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
),
products_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(p.p_retailprice) AS avg_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT
    ch.c_custkey,
    ch.c_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_spent,
    ps.p_name AS product_name,
    ps.total_avail_qty,
    ps.avg_price,
    sh.level AS supplier_level
FROM customer_orders co
JOIN customer ch ON co.c_custkey = ch.c_custkey
LEFT JOIN products_summary ps ON ps.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey = co.o_orderkey
)
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = ch.c_nationkey
WHERE COALESCE(sh.level, 0) < 3
GROUP BY ch.c_custkey, ch.c_name, ps.p_name, ps.total_avail_qty, ps.avg_price, sh.level
HAVING SUM(co.o_totalprice) > 1000
ORDER BY total_spent DESC, ch.c_name;
