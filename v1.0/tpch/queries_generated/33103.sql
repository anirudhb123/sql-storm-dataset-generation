WITH RECURSIVE last_year_orders AS (
    SELECT o_custkey, SUM(o_totalprice) AS total_spent
    FROM orders
    WHERE o_orderdate >= DATEADD(year, -1, GETDATE())
    GROUP BY o_custkey
),
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COALESCE(lo.total_spent, 0) AS last_year_spent,
           RANK() OVER (ORDER BY COALESCE(lo.total_spent, 0) DESC) AS rnk
    FROM customer c
    LEFT JOIN last_year_orders lo ON c.c_custkey = lo.o_custkey
)
SELECT 
    r.r_name, 
    SUM(ps.ps_supplycost * l.l_quantity) AS total_cost,
    AVG(l.l_extendedprice) AS average_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS suppliers_info
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderstatus = 'O' 
  AND (l.l_discount BETWEEN 0 AND 0.1 OR l.l_discount IS NULL) 
  AND (p.p_retailprice < 100 OR p.p_retailprice IS NULL)
GROUP BY r.r_name
HAVING SUM(ps.ps_supplycost * l.l_quantity) > (
    SELECT AVG(total_spent) FROM last_year_orders
)
ORDER BY total_cost DESC;
