
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, AVG(o.total_price) AS avg_order_value
    FROM customer c
    JOIN OrderDetails o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RegionWithComments AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count, 
           LISTAGG(n.n_comment, '; ') WITHIN GROUP (ORDER BY n.n_nationkey) AS combined_comments
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT *
FROM CustomerStats cs
FULL OUTER JOIN RegionWithComments rc ON cs.c_custkey = rc.nation_count
WHERE cs.avg_order_value > (SELECT AVG(avg_order_value) FROM CustomerStats)
   OR rc.combined_comments IS NOT NULL
ORDER BY cs.c_name ASC NULLS LAST
OFFSET (SELECT COUNT(*) FROM CustomerStats)
LIMIT 10;
