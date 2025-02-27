WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 5
),
CTE_Orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey
),
MaxRevenue AS (
    SELECT MAX(total_revenue) AS max_rev
    FROM CTE_Orders
),
SelectedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM CTE_Orders co
    JOIN orders o ON co.o_orderkey = o.o_orderkey
    WHERE co.total_revenue = (SELECT max_rev FROM MaxRevenue)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_discount * l.l_extendedprice) AS total_discounted,
    SUM(l.l_quantity) AS total_quantity,
    CASE 
        WHEN SUM(l.l_extendedprice) < 1000 THEN 'Low Revenue'
        WHEN SUM(l.l_extendedprice) BETWEEN 1000 AND 5000 THEN 'Medium Revenue'
        ELSE 'High Revenue'
    END AS revenue_category,
    COALESCE(MAX(sh.level), 0) AS supplier_level
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SelectedOrders so ON l.l_orderkey = so.o_orderkey
LEFT JOIN SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
WHERE p.p_brand IS NOT NULL
GROUP BY p.p_partkey, p.p_name, p.p_mfgr
HAVING COUNT(DISTINCT l.l_orderkey) > 2 OR MAX(l.l_discount) IS NULL
ORDER BY revenue_category DESC, total_orders ASC
FETCH FIRST 10 ROWS ONLY;
