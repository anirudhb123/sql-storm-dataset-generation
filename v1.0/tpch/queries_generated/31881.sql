WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000  -- Base case for recursion

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal > 1000  -- Continue recursion
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
        WHERE o2.o_orderstatus = o.o_orderstatus
    )
),
OrderDetails AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
           SUM(lo.l_quantity) AS total_quantity
    FROM lineitem lo
    GROUP BY lo.l_orderkey
)
SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
       COALESCE(SUM(od.total_quantity), 0) AS total_quantity,
       CASE 
           WHEN SUM(od.total_revenue) IS NULL THEN 'No Revenue'
           ELSE 'Revenue Acknowledged'
       END AS revenue_status,
       CASE 
           WHEN sr.level IS NOT NULL THEN 'In Hierarchy'
           ELSE 'Not In Hierarchy'
       END AS supplier_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier sr ON ps.ps_suppkey = sr.s_suppkey
LEFT JOIN OrderDetails od ON od.l_orderkey = ps.ps_partkey
LEFT JOIN FilteredOrders fo ON fo.o_orderkey = od.l_orderkey
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, sr.level
HAVING SUM(od.total_revenue) > 1000 OR COUNT(od.total_quantity) = 0
ORDER BY total_revenue DESC, p.p_partkey;
