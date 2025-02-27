WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_orderpriority, 
           1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority,
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
CustomerSummary AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, 
           COUNT(DISTINCT l.l_orderkey) AS line_item_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
PriceAnalysis AS (
    SELECT p.p_partkey, p.p_name, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
           SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ch.o_orderkey,
    ch.o_orderdate,
    cs.order_count AS customer_order_count,
    cs.line_item_count AS customer_line_item_count,
    pp.p_partkey,
    pp.p_name,
    ps.total_cost,
    pa.avg_price,
    pa.total_quantity_sold,
    ROW_NUMBER() OVER (PARTITION BY pp.p_partkey ORDER BY ps.total_cost DESC) AS cost_rank
FROM OrderHierarchy ch
JOIN CustomerSummary cs ON ch.o_custkey = cs.c_custkey
JOIN PriceAnalysis pa ON ch.o_orderkey = pa.p_partkey
LEFT JOIN SupplierPartDetails ps ON pa.p_partkey = ps.ps_partkey
LEFT JOIN part pp ON pa.p_partkey = pp.p_partkey
WHERE cs.order_count > 5
  AND cs.line_item_count IS NOT NULL
  AND pp.p_size BETWEEN 10 AND 20
ORDER BY ch.o_orderdate DESC, ps.total_cost DESC;
