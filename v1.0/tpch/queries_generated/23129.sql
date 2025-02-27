WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT sup.s_suppkey, sup.s_name, sup.s_acctbal, sh.level + 1
    FROM supplier sup
    JOIN SupplierHierarchy sh ON sup.s_suppkey = sh.s_suppkey
    WHERE sup.s_acctbal IS NOT NULL AND sup.s_acctbal >= sh.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' AND o.o_orderdate >= '2021-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 1 AND 22 AND ps.ps_availqty IS NOT NULL
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(os.total_cost) AS total_order_cost,
    COUNT(DISTINCT CASE WHEN ph.suppkey IS NOT NULL THEN ph.suppkey END) AS active_suppliers,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM
    NationRegion n
LEFT JOIN
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN
    OrderSummary os ON c.c_custkey = os.o_custkey
LEFT JOIN
    SupplierHierarchy sh ON sh.s_acctbal >= c.c_acctbal
LEFT JOIN
    PartSupplier ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
GROUP BY
    n.n_name, r.r_name
HAVING
    AVG(ps.ps_supplycost) < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_availqty IS NOT NULL)
ORDER BY
    customer_count DESC, total_order_cost
LIMIT 100 OFFSET 0;
