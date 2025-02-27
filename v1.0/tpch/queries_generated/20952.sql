WITH RECURSIVE SupplierHierarchy AS (
    SELECT DISTINCT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(s.s_name AS VARCHAR(100)) AS full_name,
           1 AS level
    FROM supplier s
    WHERE s.s_name IS NOT NULL AND s.s_nationkey IN (
        SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%'
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           CAST(CONCAT(h.full_name, ' -> ', s.s_name) AS VARCHAR(100)),
           h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.s_nationkey = h.s_nationkey
    WHERE h.level < 5
),
NonNullLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(l.l_quantity) AS item_count
    FROM lineitem l
    WHERE l.l_discount IS NOT NULL
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderdate,
           SUM(COALESCE(l.total_value, 0)) AS total_order_value,
           COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM orders o
    LEFT JOIN NonNullLineItems l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
      AND o.o_totalprice > (SELECT AVG(ps_supplycost) * COUNT(*) 
                             FROM partsupp ps WHERE ps.ps_availqty > 10)
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT fo.o_orderkey, fo.total_order_value,
           RANK() OVER (ORDER BY fo.total_order_value DESC) AS order_rank
    FROM FilteredOrders fo
    WHERE fo.total_order_value IS NOT NULL
)
SELECT rh.full_name, ro.order_rank, ro.total_order_value
FROM SupplierHierarchy rh
JOIN RankedOrders ro ON rh.s_nationkey IN (
    SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = 
        (SELECT DISTINCT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Europe%')
)
WHERE rh.level < 3
ORDER BY ro.order_rank, rh.full_name;
