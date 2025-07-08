WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT ch.c_custkey, ch.c_name, ch.c_nationkey, level + 1
    FROM CustomerHierarchy ch
    JOIN orders o ON ch.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
OrderTotal AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ch.c_name, 
    ch.level,
    r.p_name AS best_selling_part,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    CASE 
        WHEN ps.avg_supply_cost IS NULL THEN 'No suppliers available'
        ELSE 'Suppliers available'
    END AS supplier_status
FROM CustomerHierarchy ch
LEFT JOIN RankedParts r ON r.sales_rank = 1
LEFT JOIN SupplierStats ps ON ps.ps_partkey = r.p_partkey
WHERE ch.c_nationkey IS NOT NULL
ORDER BY ch.level, ch.c_name;