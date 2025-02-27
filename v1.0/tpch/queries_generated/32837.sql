WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 3
),
EnhancedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        AVG(o.o_totalprice) AS avg_order_price,
        FIRST_VALUE(o.o_orderdate) OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS first_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RegionNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    rh.r_name,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_discounted_price,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT DISTINCT o.o_orderkey) AS order_count,
    MAX(oh.first_order_date) AS recent_order_date
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN EnhancedOrders oh ON l.l_orderkey = oh.o_orderkey
LEFT JOIN RegionNations rh ON s.s_nationkey = rh.r_regionkey
WHERE p.p_retailprice > 100
AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_container, rh.r_name
HAVING COUNT(l.l_orderkey) > 0
ORDER BY total_discounted_price DESC, total_quantity DESC
LIMIT 10;
