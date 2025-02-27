WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2020-01-01'
    UNION ALL
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY o.o_orderdate DESC)
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate < DATE '2020-01-01'
    AND co.rn < 3
),
ExpensiveOrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.1
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           MIN(s.s_acctbal) AS min_acctbal, MAX(s.s_acctbal) AS max_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey
)
SELECT co.c_name, COALESCE(eo.revenue, 0) AS order_revenue, 
       ss.total_avail_qty, ss.min_acctbal, ss.max_acctbal,
       RANK() OVER (PARTITION BY co.c_custkey ORDER BY COALESCE(eo.revenue, 0) DESC) AS revenue_rank
FROM CustomerOrders co
LEFT JOIN ExpensiveOrderDetails eo ON co.o_orderkey = eo.o_orderkey
LEFT JOIN SupplierStats ss ON ss.total_avail_qty IS NOT NULL
WHERE co.o_orderdate BETWEEN DATE '2019-01-01' AND DATE '2022-12-31'
AND ((ss.min_acctbal IS NOT NULL AND ss.min_acctbal > 0) OR ss.max_acctbal IS NULL)
ORDER BY co.c_name, revenue_rank;
