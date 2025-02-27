WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal, s_comment, 
           1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.n_nationkey, s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3 AND s.s_acctbal < sh.acctbal
),
ActiveOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
LineItemAggregates AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, 
           AVG(l.l_quantity) AS avg_quantity, 
           COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierStats AS (
    SELECT sh.s_nationkey, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, 
           AVG(sh.s_acctbal) AS avg_balance
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(ss.supplier_count, 0) AS total_suppliers,
    COALESCE(ls.total_price, 0) AS total_order_value,
    COALESCE(ls.avg_quantity, 0) AS average_item_quantity,
    CASE 
        WHEN ao.price_rank IS NOT NULL THEN 'Top Order'
        ELSE 'Other Order'
    END AS order_rank
FROM nation n
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN LineItemAggregates ls ON n.n_nationkey = ls.l_orderkey
LEFT JOIN ActiveOrders ao ON ao.o_orderkey = ls.l_orderkey
WHERE r.r_name LIKE '%North%'
ORDER BY total_order_value DESC, n.n_name;
