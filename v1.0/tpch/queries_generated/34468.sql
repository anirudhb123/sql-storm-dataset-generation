WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 500
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_nationkey
), TotalOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    GROUP BY o.o_custkey
), CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COALESCE(to.order_count, 0) AS order_count
    FROM customer c
    LEFT JOIN TotalOrders to ON c.c_custkey = to.o_custkey
), PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.total_available
    FROM part p
    JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100 AND ps.total_available < 1000
), RankedSuppliers AS (
    SELECT s.s_name, s.s_acctbal, DENSE_RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), OrderStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(oi.l_extendedprice * (1 - oi.l_discount)) AS total_spent,
        AVG(oi.l_discount) AS average_discount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem oi ON o.o_orderkey = oi.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' 
    GROUP BY c.c_custkey, c.c_name
)
SELECT
    ch.c_custkey,
    ch.c_name,
    sh.level AS supplier_level,
    r.rank AS supplier_rank,
    hs.p_partkey,
    hs.p_name,
    hs.p_retailprice,
    hs.total_available,
    os.total_orders,
    os.total_spent,
    os.average_discount
FROM CustomerDetails ch
JOIN SupplierHierarchy sh ON ch.c_nationkey = sh.s_nationkey
JOIN RankedSuppliers r ON r.s_acctbal >= ch.c_acctbal
JOIN HighValueParts hs ON hs.p_partkey IN (
    SELECT DISTINCT ps.ps_partkey
    FROM partsupp ps
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    WHERE li.l_shipdate > CURRENT_DATE - INTERVAL '30 days'
)
LEFT JOIN OrderStats os ON ch.c_custkey = os.c_custkey
WHERE ch.order_count > 0
ORDER BY sh.level, r.rank, hs.p_retailprice DESC;
