WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
DiscountedLines AS (
    SELECT l_orderkey, l_partkey, SUM(l_extendedprice * (1 - l_discount)) AS total_discounted_price
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_orderkey, l_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -3, CURRENT_DATE)
),
SupplierStats AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS part_count, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT n.n_name, 
       s.s_name AS supplier_name, 
       SUM(dl.total_discounted_price) AS total_discount, 
       AVG(hvo.o_totalprice) AS avg_order_value, 
       MAX(ss.part_count) AS supplier_part_count
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN DiscountedLines dl ON sh.supp_skey = dl.l_orderkey
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = dl.l_orderkey
LEFT JOIN SupplierStats ss ON sh.s_suppkey = ss.s_suppkey
WHERE n.r_regionkey IS NOT NULL
GROUP BY n.n_name, s.s_name
HAVING COUNT(dl.l_orderkey) > 5
ORDER BY total_discount DESC NULLS LAST;
