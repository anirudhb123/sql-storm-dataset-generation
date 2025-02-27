WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT od.o_orderkey, od.total_revenue, od.item_count
    FROM OrderDetails od
    WHERE od.total_revenue > (
        SELECT AVG(total_revenue) FROM OrderDetails
    )
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    MIN(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice END) AS min_returned_value,
    MAX(CASE WHEN l.l_linestatus = 'O' THEN l.l_discount END) AS max_open_discount
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
WHERE p.p_retailprice > (
    SELECT AVG(p_retailprice) FROM part
) AND s.s_acctbal IS NOT NULL
GROUP BY p.p_name
HAVING COUNT(DISTINCT l.l_orderkey) > 0
ORDER BY total_quantity DESC, p.p_name ASC;