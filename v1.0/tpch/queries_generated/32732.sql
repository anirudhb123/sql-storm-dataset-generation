WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 1 AS lvl
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.lvl + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
    WHERE sh.lvl < 5
),
LatestOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           STRING_AGG(DISTINCT n.n_name, ', ') AS nations,
           AVG(l.l_quantity) AS avg_quantity
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_retailprice > (
        SELECT AVG(p_retailprice) FROM part
    )
),
SupplierStats AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail, SUM(ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
)
SELECT c.c_name, cs.order_count, cs.total_revenue, cs.nations,
       COALESCE(sh.lvl, 0) AS supplier_level, 
       CASE WHEN cs.avg_quantity IS NULL THEN 'No orders' ELSE TO_CHAR(cs.avg_quantity, 'FM9999.00') END AS average_qty,
       (SELECT SUM(ps.ps_availqty) FROM partsupp ps INNER JOIN FilteredParts fp ON ps.ps_partkey = fp.p_partkey) AS total_filtered_qty
FROM CustomerStats cs
LEFT JOIN SupplierHierarchy sh ON cs.order_count > 5
LEFT JOIN SupplierStats ss ON ss.ps_suppkey = sh.s_suppkey
WHERE cs.total_revenue > (
    SELECT AVG(total_revenue) FROM CustomerStats
)
ORDER BY cs.total_revenue DESC
LIMIT 10;
