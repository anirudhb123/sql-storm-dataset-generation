WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
AggLineItems AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_partkey
),
BestSellingParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, a.total_revenue
    FROM part p
    JOIN AggLineItems a ON p.p_partkey = a.l_partkey
    ORDER BY a.total_revenue DESC
    LIMIT 5
),
RegionalSupplier AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    ch.c_custkey,
    ch.c_name,
    COALESCE(ch.order_count, 0) AS order_count,
    bp.p_name,
    bp.total_revenue,
    r.region_name,
    r.supplier_count
FROM CustomerOrders ch
LEFT JOIN BestSellingParts bp ON ch.order_count > 0
LEFT JOIN RegionalSupplier r ON r.region_name IS NOT NULL
WHERE (ch.order_count > 10 OR r.supplier_count > 5)
ORDER BY ch.c_custkey, bp.total_revenue DESC;
