WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS total_parts, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, 
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT 
    ch.c_name AS customer_name,
    s.s_name AS supplier_name,
    oi.total_price AS order_price,
    si.total_parts AS supplier_part_count,
    si.total_cost AS supplier_total_cost,
    CASE 
        WHEN ch.level IS NOT NULL THEN 'In Hierarchy' 
        ELSE 'Not in Hierarchy' 
    END AS hierarchy_status
FROM CustomerHierarchy ch
FULL OUTER JOIN SupplierInfo si ON si.total_parts > 1
INNER JOIN OrderSummary oi ON oi.total_price > 1000
WHERE si.total_cost IS NOT NULL OR ch.c_custkey IS NULL
ORDER BY ch.c_name, si.total_cost DESC;
