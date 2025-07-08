WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O' AND o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, h.level + 1
    FROM orders o
    JOIN OrderHierarchy h ON o.o_custkey = h.o_custkey
    WHERE o.o_orderdate > h.o_orderdate
      AND o.o_orderstatus = 'O'
),
MaxPrices AS (
    SELECT l.l_orderkey, MAX(l.l_extendedprice) AS max_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
WeeklySales AS (
    SELECT DATE_TRUNC('week', o.o_orderdate) AS week_start,
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY week_start
),
CustomerStats AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT OUTER JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    n.n_name,
    r.r_name,
    SUM(COALESCE(ps.ps_supplycost * ps.ps_availqty, 0)) AS total_cost,
    AVG(c.total_spent) AS avg_spending,
    MAX(m.max_price) AS max_lineitem_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    (SELECT COUNT(DISTINCT l.l_orderkey)
     FROM lineitem l
     WHERE l.l_returnflag = 'R') AS returned_items
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN MaxPrices m ON ps.ps_partkey = m.l_orderkey
LEFT JOIN CustomerStats c ON s.s_suppkey = c.c_custkey
LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
WHERE r.r_name LIKE 'N%'
GROUP BY n.n_name, r.r_name
HAVING AVG(c.total_spent) > 1000
ORDER BY total_cost DESC, n.n_name;