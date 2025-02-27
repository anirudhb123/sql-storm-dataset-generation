WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM partsupp ps
    JOIN SalesHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 50000 AND sh.level < 3
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 1
),
DiscountedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.1 AND l.l_discount < 0.5
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sh.s_suppkey, 0) AS supplier_key,
    TOP.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    AVG(d.total_price) AS avg_discounted_price
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SalesHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN TopRegions TOP ON TOP.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey LIMIT 1))
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN DiscountedOrders d ON d.o_orderkey = l.l_orderkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 200.00)
GROUP BY p.p_partkey, p.p_name, TOP.r_name, sh.s_suppkey
HAVING AVG(d.total_price) IS NOT NULL
ORDER BY order_count DESC, avg_discounted_price DESC;
