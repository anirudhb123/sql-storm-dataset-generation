WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 1000 AND ch.level < 5
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
    FROM orders o
    WHERE o.o_totalprice > 5000 AND o.o_orderstatus = 'O'
),
SupplierPriceRank AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS price_rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
LineItemStats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS line_count,
           AVG(l.l_discount) AS avg_discount
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2022-01-01'
    GROUP BY l.l_orderkey
)
SELECT c.c_name, 
       SUM(lo.total_revenue) AS total_revenue,
       COUNT(DISTINCT lo.l_orderkey) AS order_count,
       AVG(spr.price_rank) AS avg_supplier_rank
FROM CustomerHierarchy c
LEFT JOIN HighValueOrders ho ON c.c_custkey = ho.o_custkey
LEFT JOIN LineItemStats lo ON ho.o_orderkey = lo.l_orderkey
LEFT JOIN SupplierPriceRank spr ON lo.l_orderkey = spr.ps_partkey
GROUP BY c.c_name
HAVING SUM(lo.total_revenue) IS NOT NULL 
       AND COUNT(DISTINCT lo.l_orderkey) > 2
ORDER BY total_revenue DESC
LIMIT 10;
