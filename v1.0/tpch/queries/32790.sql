WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 
           0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh.o_orderstatus,
           oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey AND o.o_orderstatus = 'F'  
),
RankedSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY ps.ps_suppkey
),
LineItemSummary AS (
    SELECT l.l_orderkey, COUNT(*) AS total_items,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY l.l_orderkey
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(ls.total_revenue) AS total_revenue, 
       AVG(r.total_cost) AS avg_supplier_cost
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN LineItemSummary ls ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE ls.l_orderkey = o.o_orderkey)
LEFT JOIN RankedSuppliers r ON r.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey = ls.l_orderkey LIMIT 1)
WHERE n.n_name IS NOT NULL AND ls.total_items IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_revenue DESC;