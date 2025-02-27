WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 5000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE c.c_acctbal > ch.c_acctbal
),

SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),

HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
    )
),

LineItemStats AS (
    SELECT l.l_orderkey, COUNT(*) AS item_count, AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    ch.c_name,
    COALESCE(lp.item_count, 0) AS order_item_count,
    COALESCE(lp.avg_price, 0) AS avg_item_price,
    sp.total_supply_value,
    CASE 
        WHEN sp.total_supply_value IS NOT NULL THEN 'Above Average Supply'
        ELSE 'Below Average Supply'
    END AS supply_status
FROM CustomerHierarchy ch
LEFT JOIN LineItemStats lp ON ch.c_custkey = lp.l_orderkey
LEFT JOIN SupplierPerformance sp ON sp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (
    SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = lp.l_orderkey LIMIT 1
) LIMIT 1)
WHERE ch.level < 3
ORDER BY ch.c_name, supply_status DESC;
