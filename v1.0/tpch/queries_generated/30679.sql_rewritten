WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 as level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > (SELECT MAX(o_orderdate) FROM orders WHERE o_custkey = oh.o_custkey) 
    AND oh.level < 5
)

SELECT c.c_name, r.r_name, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
       AVG(s.s_acctbal) AS avg_supplier_balance,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
INNER JOIN orders o ON c.c_custkey = o.o_custkey
INNER JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON li.l_partkey = p.p_partkey
WHERE (o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
       AND c.c_acctbal IS NOT NULL
       AND r.r_name LIKE 'NORTH%')
GROUP BY c.c_name, r.r_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY total_revenue DESC
LIMIT 10;