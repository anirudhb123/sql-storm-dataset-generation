WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, 0 AS level
    FROM supplier s
    WHERE s.acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.n_nationkey
    WHERE sh.level < 3
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_items
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT 
    n.n_name,
    COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
    AVG(od.total_items) FILTER (WHERE od.total_items > 0) AS avg_items_per_order,
    COUNT(DISTINCT oh.o_orderkey) AS total_orders,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.n_nationkey
LEFT JOIN RankedOrders oh ON sh.s_suppkey = oh.o_orderkey
LEFT JOIN OrderDetails od ON oh.o_orderkey = od.l_orderkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
