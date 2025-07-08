
WITH RECURSIVE Order_CTE AS (
    SELECT o_orderkey, 
           o_custkey, 
           o_orderdate, 
           o_totalprice, 
           1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           oc.level + 1
    FROM orders o
    JOIN Order_CTE oc ON o.o_custkey = oc.o_custkey
    WHERE o.o_orderdate > oc.o_orderdate
      AND o.o_orderstatus = 'O'
)

SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_line_quantity,
    MAX(l.l_tax) AS max_tax_rate,
    MIN(CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS any_returned_order,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM lineitem l
INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
INNER JOIN customer c ON o.o_custkey = c.c_custkey
INNER JOIN supplier s ON l.l_suppkey = s.s_suppkey
INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
INNER JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN Order_CTE oc ON c.c_custkey = oc.o_custkey AND oc.level > 1
WHERE l.l_shipdate BETWEEN DATE '1998-10-01' - INTERVAL '1 year' AND DATE '1998-10-01'
  AND l.l_discount > 0.1
  AND r.r_name IS NOT NULL
  AND n.n_name IS NOT NULL
  AND c.c_acctbal IS NOT NULL
GROUP BY r.r_name, n.n_name, c.c_name, c.c_custkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(order_total)
    FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS order_total
        FROM lineitem
        JOIN orders ON lineitem.l_orderkey = orders.o_orderkey
        GROUP BY orders.o_custkey
    ) AS subquery
)
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
