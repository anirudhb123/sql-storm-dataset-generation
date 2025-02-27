WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 as level
    FROM supplier
    WHERE s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000
),

AggregatedOrderData AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
),

CustomerOrderSegment AS (
    SELECT c.c_custkey, c.c_mktsegment, a.total_revenue
    FROM customer c
    JOIN AggregatedOrderData a ON c.c_custkey = a.o_custkey
),

TopCustomers AS (
    SELECT c.mktsegment, c.c_custkey, c.total_revenue,
           RANK() OVER (PARTITION BY c.mktsegment ORDER BY c.total_revenue DESC) AS revenue_rank
    FROM CustomerOrderSegment c
)

SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
       COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
       E.level AS supplier_level, COUNT(DISTINCT o.o_orderkey) AS order_count
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy E ON s.s_suppkey = E.s_suppkey
LEFT JOIN orders o ON o.o_custkey IN (SELECT c.c_custkey FROM TopCustomers c WHERE c.revenue_rank = 1)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, E.level
HAVING SUM(ps.ps_availqty) > 100
ORDER BY total_available_qty DESC, p.p_retailprice ASC;
