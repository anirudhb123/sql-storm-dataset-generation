WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey < 10  
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
    WHERE nh.level < 5
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) < 500
),
OrderStats AS (
    SELECT fo.o_orderkey, fo.o_custkey, fo.order_total,
           ROW_NUMBER() OVER (PARTITION BY fo.o_custkey ORDER BY fo.order_total DESC) AS rn,
           LAG(fo.order_total) OVER (PARTITION BY fo.o_custkey ORDER BY fo.o_orderdate) AS previous_order_total
    FROM FilteredOrders fo
)
SELECT 
    nh.n_name AS nation_name,
    ts.s_name AS top_supplier,
    os.o_orderkey,
    os.order_total,
    COALESCE(os.previous_order_total, 0) AS previous_total,
    CASE 
        WHEN os.order_total IS NULL THEN 'No Orders Yet'
        WHEN os.order_total > COALESCE(os.previous_order_total, 0) THEN 'Increased Order Total'
        ELSE 'Decreased Order Total'
    END AS order_trend
FROM NationHierarchy nh
LEFT JOIN customer c ON c.c_nationkey = nh.n_nationkey
LEFT JOIN TopSuppliers ts ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_size BETWEEN 10 AND 30
    )
)
JOIN OrderStats os ON os.o_custkey = c.c_custkey
WHERE nh.level = 2 OR (os.order_total IS NOT NULL AND nh.level > 1)
ORDER BY nh.n_name, ts.s_name, os.order_total DESC;