WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_acctbal < ch.c_acctbal
    WHERE c.c_custkey <> ch.c_custkey
), 
SupplierShare AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrdersWithLineItems AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           AVG(l.l_quantity) AS avg_quantity,
           o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT 
    c.c_name,
    c.c_acctbal,
    (SELECT COUNT(DISTINCT o.o_orderkey)
     FROM orders o
     JOIN lineitem l ON o.o_orderkey = l.l_orderkey
     WHERE o.o_custkey = c.c_custkey AND o.o_orderstatus = 'O') AS total_orders,
    s.s_name,
    s.total_supply_cost,
    oh.total_price,
    oh.avg_quantity
FROM CustomerHierarchy c
LEFT JOIN (
    SELECT ps.ps_partkey, s.s_name, ss.total_supply_cost
    FROM SupplierShare ss
    JOIN supplier s ON ss.ps_partkey = ps.ps_partkey
) s ON s.ps_partkey = (
    SELECT ps1.ps_partkey
    FROM partsupp ps1
    WHERE ps1.ps_suppkey = (SELECT MIN(ps2.ps_suppkey) FROM partsupp ps2 WHERE ps1.ps_partkey = ps2.ps_partkey)
    LIMIT 1
)
JOIN OrdersWithLineItems oh ON oh.total_price > 5000
WHERE c.level >= 1 AND c.c_acctbal IS NOT NULL
ORDER BY c.c_acctbal DESC, total_orders DESC;
