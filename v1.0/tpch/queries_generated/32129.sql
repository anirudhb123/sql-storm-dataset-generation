WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderdate < DATEADD(DAY, -30, oh.o_orderdate)
),
SupplierAggregations AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 20
    GROUP BY ps.s_suppkey
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemStats AS (
    SELECT l.l_suppkey, AVG(l.l_discount) AS avg_discount, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_suppkey
)
SELECT DISTINCT r.r_name, 
    COALESCE(c.c_name, 'Unknown') AS customer_name,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.total_sales) AS total_lineitem_sales,
    p.p_name,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.total_sales) DESC) AS sales_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierAggregations AS sa ON sa.s_suppkey = s.s_suppkey
LEFT JOIN CustomerOrderCounts AS c ON c.c_custkey = s.s_suppkey
LEFT JOIN LineItemStats AS l ON l.l_suppkey = s.s_suppkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN part p ON p.p_partkey = l.l_suppkey
WHERE sa.total_cost IS NOT NULL
AND l.avg_discount < 0.1
AND o.o_orderdate > '2023-01-01'
GROUP BY r.r_name, customer_name, p.p_name
HAVING COUNT(o.o_orderkey) > 1
ORDER BY r.r_name, sales_rank;
