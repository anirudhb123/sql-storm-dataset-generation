
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_orderdate) AS last_order_date,
    CASE 
        WHEN MAX(o.o_orderdate) < DATE '1998-10-01' - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status,
    r.r_name AS region_name
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
WHERE ps.ps_availqty > 0
GROUP BY c.c_custkey, c.c_name, c.c_acctbal, r.r_name, n.n_nationkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(total_revenue)
    FROM (
        SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        GROUP BY c.c_custkey
    ) AS avg_revenue
)
ORDER BY total_revenue DESC
LIMIT 10;
