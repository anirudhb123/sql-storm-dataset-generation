WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 30000 AND sh.level < 3
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS recent_order
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_return_qty,
        AVG(l.l_discount) AS avg_discount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name, 
    s.s_name,
    sh.level,
    r.o_orderkey,
    r.o_orderdate,
    ss.total_return_qty,
    ss.avg_discount,
    ss.total_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
LEFT JOIN RecentOrders r ON r.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = s.s_nationkey
    )
)
JOIN SupplierStats ss ON ss.ps_partkey = ps.ps_partkey
WHERE (s.s_acctbal IS NULL OR s.s_acctbal < 100000)
AND p.p_type LIKE '%BRASS%'
ORDER BY r.o_orderdate DESC, ss.total_revenue DESC;
