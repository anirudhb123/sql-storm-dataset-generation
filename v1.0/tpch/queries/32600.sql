WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
        WHERE s_nationkey IN (
            SELECT n_nationkey
            FROM nation
            WHERE n_name LIKE '%land%'
        )
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    AND EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_custkey = o.o_custkey
        AND c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
    )
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierTotals AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(fo.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(st.total_cost), 0) AS total_cost,
    CASE 
        WHEN SUM(fo.total_revenue) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Generated'
    END AS revenue_status
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN FilteredOrders fo ON o.o_orderkey = fo.o_orderkey
LEFT JOIN SupplierTotals st ON c.c_nationkey = st.s_suppkey
WHERE n.n_comment NOT LIKE '%sample%'
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_revenue DESC
LIMIT 10;
