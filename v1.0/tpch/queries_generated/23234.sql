WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS acctbal_rank
    FROM supplier s
),
ValidParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_type,
           COALESCE(NULLIF(p.p_retailprice, 0), 1) AS adjusted_price
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 30 AND p.p_type LIKE '%metal%'
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
FilteredOrders AS (
    SELECT od.o_orderkey, od.o_orderstatus, od.total_amount
    FROM OrderDetails od
    WHERE od.total_amount > (
        SELECT AVG(total_amount) FROM OrderDetails) * 0.75
)
SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_type,
       s.s_name AS supplier_name, s.s_acctbal, ss.acctbal_rank,
       o.o_orderkey, o.o_orderstatus, o.total_amount,
       CASE 
           WHEN o.total_amount IS NULL THEN 'No Order'
           ELSE 'Order Present'
       END AS order_status_check
FROM ValidParts p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers ss ON ps.ps_suppkey = ss.s_suppkey AND ss.acctbal_rank <= 5
LEFT JOIN FilteredOrders o ON ps.ps_suppkey = o.o_orderkey
WHERE p.adjusted_price > (
    SELECT AVG(adjusted_price) FROM ValidParts) 
    AND (s_name IS NOT NULL OR p.p_comment LIKE '%urgent%')
ORDER BY p.p_partkey, s.s_name, o.o_orderstatus ASC
LIMIT 100;
