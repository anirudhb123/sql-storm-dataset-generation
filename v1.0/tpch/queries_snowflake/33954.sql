WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),

TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(co.total_spent) AS total
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total DESC
    LIMIT 10
),

ProductPrices AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

FinalMetrics AS (
    SELECT 
        tc.c_custkey,
        tc.c_name,
        pp.p_partkey,
        pp.p_name,
        pp.avg_supplycost,
        CASE 
            WHEN tc.total > 50000 THEN 'High Roller'
            WHEN tc.total > 25000 THEN 'Medium Roller'
            ELSE 'Low Roller'
        END AS spending_category
    FROM TopCustomers tc
    LEFT JOIN ProductPrices pp ON tc.c_custkey % 10 = pp.p_partkey % 10
)

SELECT f.c_custkey, f.c_name, f.p_partkey, f.p_name, f.avg_supplycost, f.spending_category
FROM FinalMetrics f
WHERE f.avg_supplycost IS NOT NULL
ORDER BY f.spending_category, f.avg_supplycost DESC
LIMIT 50;
