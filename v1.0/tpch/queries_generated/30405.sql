WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT
    r.r_name,
    n.n_name,
    c.c_name,
    coalesce(s.s_name, 'No Supplier') AS supplier_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(co.total_spent) AS average_spent,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    MAX(ps.ps_availqty) AS max_available_quantity
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem li ON p.p_partkey = li.l_partkey
JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN customer_orders co ON o.o_custkey = co.c_custkey
GROUP BY r.r_name, n.n_name, c.c_name, s.s_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 5000
ORDER BY revenue DESC, total_orders DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
