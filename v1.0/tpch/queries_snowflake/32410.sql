
WITH RECURSIVE CustomerCTE AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 5000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal * 0.9, level + 1
    FROM CustomerCTE cte
    JOIN customer c ON cte.c_custkey = c.c_custkey
    WHERE c.c_acctbal * 0.9 > 5000 AND level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
SupplierRanking AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    ccte.c_name AS customer_name,
    os.total_revenue AS revenue,
    sr.s_name AS supplier_name,
    sr.rank AS supplier_rank,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status,
    COALESCE(ccte.level, -1) AS customer_level,
    CONCAT('Customer: ', ccte.c_name, ', Revenue: ', COALESCE(CAST(os.total_revenue AS TEXT), '0')) AS summary
FROM CustomerCTE ccte
LEFT JOIN OrderSummary os ON ccte.c_custkey = os.o_orderkey
LEFT JOIN SupplierRanking sr ON sr.rank <= 5
WHERE COALESCE(ccte.c_acctbal, 0) > 10000
ORDER BY ccte.c_name, os.total_revenue DESC
LIMIT 10;
