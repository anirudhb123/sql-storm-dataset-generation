WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_custkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_retailprice,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available,
    cs.order_count,
    cs.total_spent,
    (SELECT COUNT(DISTINCT l.l_orderkey) 
     FROM lineitem l
     INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
     WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31' 
       AND l.l_returnflag = 'R') AS total_returns
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN customer_summary cs ON cs.order_count > 0 
WHERE p.p_retailprice > 50 
  AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_comment IS NOT NULL)
GROUP BY p.p_name, p.p_retailprice, s.s_name, cs.order_count, cs.total_spent
HAVING SUM(ps.ps_availqty) > 100
ORDER BY total_spent DESC, p.p_name
FETCH FIRST 10 ROWS ONLY;
