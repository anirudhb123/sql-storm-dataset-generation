
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_orderkey) AS total_items,
           CASE 
               WHEN COUNT(DISTINCT l.l_orderkey) > 5 THEN 'High Volume'
               ELSE 'Low Volume'
           END AS order_type
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(COALESCE(os.total_price, 0)) AS total_order_revenue,
       LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderStats os ON c.c_custkey = os.o_orderkey
LEFT JOIN HighValueParts p ON os.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l
    WHERE l.l_partkey = p.p_partkey
) AND os.order_type = 'High Volume'
WHERE r.r_name IS NOT NULL
AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
AND p.p_retailprice IS NOT NULL
GROUP BY r.r_regionkey, r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 0
ORDER BY r.r_regionkey ASC NULLS LAST;
