
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
    UNION ALL
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY oh.o_orderkey ORDER BY oh.o_orderdate DESC)
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE oh.rnk < 3
),
SupplierStats AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RevenuePerCustomer AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
BestPartSupplies AS (
    SELECT p.p_partkey, p.p_name, 
           COALESCE(SUM(ps.ps_availqty), 0) AS available_qty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(SUM(ps.ps_availqty), 0) DESC) AS rnk
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    n.n_name,
    MAX(COALESCE(c.total_revenue, 0)) AS max_revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(sp.total_cost) AS avg_supplier_cost,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_shipdate > DATE '1998-10-01' - INTERVAL '90 days') AS recent_shipments
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN RevenuePerCustomer c ON s.s_suppkey = c.c_custkey
LEFT JOIN BestPartSupplies p ON s.s_suppkey = p.p_partkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY max_revenue DESC, n.n_name;
