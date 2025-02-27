WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COALESCE(SUM(oh.o_totalprice), 0) AS total_order_value,
    SUM(ss.total_supply_cost) AS total_supplier_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(oh.o_totalprice) DESC) AS ranking
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
LEFT JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
LEFT JOIN SupplierSummary ss ON EXISTS (
    SELECT 1 
    FROM lineitem l 
    WHERE l.l_orderkey = o.o_orderkey 
    AND l.l_suppkey = ss.s_suppkey
)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_order_value DESC NULLS LAST;
