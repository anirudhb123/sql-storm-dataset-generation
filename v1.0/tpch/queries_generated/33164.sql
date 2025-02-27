WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE o.o_orderstatus = 'O'
),

FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
),

OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
           DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(od.net_value) AS total_revenue,
    COUNT(DISTINCT oh.o_orderkey) AS total_orders,
    MAX(oh.level) AS max_order_level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN FilteredSuppliers fs ON s.s_suppkey = fs.s_suppkey
LEFT JOIN OrderDetails od ON od.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = fs.s_suppkey)
LEFT JOIN OrderHierarchy oh ON oh.o_orderkey = od.o_orderkey
WHERE n.n_name IS NOT NULL 
AND (fs.total_cost IS NOT NULL OR fs.total_cost IS NOT NULL)
GROUP BY r.r_name, n.n_name, s.s_name
HAVING SUM(od.net_value) > 10000
ORDER BY total_revenue DESC;
