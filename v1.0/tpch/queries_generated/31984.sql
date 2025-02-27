WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, sh.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_quantity,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
JoinResults AS (
    SELECT ch.c_custkey, ch.c_name, ps.p_partkey, ps.p_name,
           os.total_revenue, cs.order_count
    FROM CustomerOrders ch
    FULL OUTER JOIN PartSupplier ps ON ps.total_available_quantity > 100
    LEFT JOIN OrderStats os ON os.unique_customers > 10 AND os.total_revenue > 5000
    LEFT JOIN OrderStats cs ON cs.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O'
    )
)
SELECT j.c_custkey, j.c_name, j.p_partkey, j.p_name,
       COALESCE(j.total_revenue, 0) AS revenue,
       COALESCE(j.order_count, 0) AS orders_count,
       ROW_NUMBER() OVER (PARTITION BY j.c_custkey ORDER BY j.total_revenue DESC) AS revenue_rank
FROM JoinResults j
ORDER BY j.c_custkey, revenue_rank;
