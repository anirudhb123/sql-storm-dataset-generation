WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
AggregateLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           COUNT(DISTINCT l.l_partkey) AS part_count,
           AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    WHERE l.l_shipdate > '1996-01-01' 
    GROUP BY l.l_orderkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, 
           o.o_totalprice,
           COALESCE(SUM(al.avg_quantity), 0) AS total_avg_quantity
    FROM orders o
    LEFT JOIN AggregateLineItems al ON o.o_orderkey = al.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING o.o_totalprice > 10000 AND COALESCE(SUM(al.avg_quantity), 0) > 5
),
QualifiedSuppliers AS (
    SELECT ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_available_qty
    FROM partsupp ps
    WHERE EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE s.s_suppkey = ps.ps_suppkey 
        AND s.s_acctbal > 5000
    )
    GROUP BY ps.ps_suppkey
)
SELECT s.s_name,
       s.s_acctbal,
       h.o_orderkey,
       h.o_totalprice,
       q.total_available_qty
FROM supplier s
JOIN HighValueOrders h ON s.s_suppkey = h.o_orderkey
LEFT JOIN QualifiedSuppliers q ON s.s_suppkey = q.ps_suppkey
WHERE s.s_acctbal IS NOT NULL
ORDER BY s.s_name, h.o_totalprice DESC
LIMIT 10;