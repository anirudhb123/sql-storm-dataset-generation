WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority,
           CAST(0 AS INT) AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority,
           oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus <> 'O'
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(line.l_extendedprice * (1 - line.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    MAX(oh.o_totalprice) AS max_order_total,
    MIN(line.l_quantity) AS min_line_quantity,
    SUM(CASE WHEN line.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(line.l_extendedprice) DESC) AS rank
FROM lineitem line
JOIN orders o ON line.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON line.l_suppkey = s.s_suppkey
JOIN partsupp ps ON line.l_partkey = ps.ps_partkey AND line.l_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
WHERE line.l_shipdate >= '2023-01-01'
  AND line.l_shipdate < '2024-01-01'
  AND (o.o_orderstatus IN ('O', 'F') OR oh.o_orderkey IS NOT NULL)
GROUP BY r.r_name, n.n_name, s.s_name
HAVING SUM(line.l_extendedprice) > 1000000
ORDER BY total_revenue DESC, region_name;
