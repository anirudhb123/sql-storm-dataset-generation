WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_nationkey, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.p_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_supplycost < 100
),
TotalRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2021-01-01' AND o.o_orderdate < '2022-01-01'
    GROUP BY c.c_custkey
)
SELECT 
    sh.s_name,
    COUNT(DISTINCT th.c_custkey) AS total_customers,
    SUM(th.revenue) AS total_revenue,
    AVG(sh.ps_supplycost) AS avg_supply_cost
FROM SupplierHierarchy sh
JOIN TotalRevenue th ON sh.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sh.s_suppkey)
GROUP BY sh.s_name
ORDER BY total_revenue DESC
LIMIT 10;
