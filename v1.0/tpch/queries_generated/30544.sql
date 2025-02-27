WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
, OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS total_orders
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(o.total_revenue) AS max_order_revenue,
    COUNT(DISTINCT CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderkey END) AS finalized_orders,
    COUNT(o.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_quantity) DESC) AS rank,
    REGEXP_COUNT(p.p_comment, 'excellent|good|average', 'i') AS comment_quality
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderSummary o ON l.l_orderkey = o.o_orderkey
GROUP BY p.p_partkey, p.p_name, s.s_name
HAVING AVG(l.l_extendedprice) > 100 AND COUNT(o.o_orderkey) > 10
ORDER BY returned_quantity DESC, avg_price ASC;
