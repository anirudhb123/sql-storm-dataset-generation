
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           1 AS level 
    FROM orders o 
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'P'
    AND oh.level < 5
), CustomerBalance AS (
    SELECT c.c_custkey, 
           SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open_orders,
           SUM(CASE WHEN o.o_orderstatus = 'C' THEN o.o_totalprice ELSE 0 END) AS total_closed_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), SupplierParts AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT p.p_partkey) AS unique_parts
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(COALESCE(cb.total_open_orders, 0)) AS total_open_order_value,
    AVG(sp.total_available) AS avg_available_quantity,
    MAX(sp.unique_parts) AS max_unique_parts,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(COALESCE(cb.total_open_orders, 0)) DESC) AS region_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerBalance cb ON cb.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN SupplierParts sp ON sp.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey)
GROUP BY r.r_name
HAVING AVG(sp.total_available) > 50 AND COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY region_rank;
