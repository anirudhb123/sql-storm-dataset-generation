WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
AvailableParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'Unknown'
               WHEN c.c_acctbal < 500.00 THEN 'Low Balance'
               ELSE 'High Balance'
           END AS balance_status
    FROM customer c
    WHERE c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
),
DetailedOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           COUNT(l.l_orderkey) AS item_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice
)
SELECT 
    r.rnk,
    r.s_name,
    COALESCE(aps.total_available, 0) AS available_qty,
    fd.c_name,
    fd.balance_status,
    do.o_orderkey,
    do.item_count,
    do.total_revenue,
    CASE 
        WHEN r.rnk = 1 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_rank_status
FROM RankedSuppliers r
LEFT JOIN AvailableParts aps ON r.s_suppkey = aps.ps_partkey
JOIN FilteredCustomers fd ON r.s_suppkey = fd.c_custkey
INNER JOIN DetailedOrders do ON fd.c_custkey = do.o_orderkey
WHERE (do.total_revenue IS NOT NULL AND do.o_orderstatus = 'O')
  AND (fd.balance_status = 'High Balance' OR (fd.balance_status = 'Low Balance' AND do.item_count > 2))
ORDER BY r.rnk, do.total_revenue DESC
LIMIT 50;
