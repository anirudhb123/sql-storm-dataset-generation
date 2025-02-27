WITH RECURSIVE nation_tree AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 1 as level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'Europe')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nt.level + 1
    FROM nation n
    JOIN nation_tree nt ON n.n_regionkey = nt.n_nationkey
)
, avg_supplier_cost AS (
    SELECT ps_partkey, AVG(ps_supplycost) as avg_cost
    FROM partsupp
    GROUP BY ps_partkey
)
, customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) as total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
)
SELECT n.n_name AS nation_name,
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
       COUNT(DISTINCT c.c_custkey) AS unique_customers,
       CASE 
            WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN AVG(c.total_spent) 
            ELSE 0 
       END AS average_spent,
       MAX(p.p_retailprice) AS max_part_price,
       MIN(pc.avg_cost) AS min_supplier_cost
FROM lineitem l
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer_orders c ON c.c_custkey = o.o_custkey
JOIN partsupp ps ON ps.ps_partkey = l.l_partkey
JOIN avg_supplier_cost pc ON pc.ps_partkey = ps.ps_partkey
JOIN nation_tree n ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ps.ps_suppkey)
WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
  AND (l.l_returnflag = 'N' OR l.l_tax IS NULL)
GROUP BY n.n_name
HAVING total_revenue > (SELECT AVG(total_spent) FROM customer_orders)
   OR (COUNT(l.l_orderkey) > 1 AND MAX(l.l_extendedprice) > 1000)
ORDER BY total_revenue DESC, unique_customers ASC
LIMIT 10;
