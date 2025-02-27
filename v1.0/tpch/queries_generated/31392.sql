WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 500.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartPriceSummary AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
TopSuppliers AS (
    SELECT s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate > '2023-01-01'
    GROUP BY s.s_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
CustomerStats AS (
    SELECT c.c_custkey, AVG(o.o_totalprice) AS avg_order_value, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    rg.r_name,
    ph.p_partkey,
    COALESCE(ph.total_supplycost, 0) AS total_supplycost,
    ts.total_sales,
    cs.avg_order_value,
    cs.order_count,
    sh.level
FROM region rg
LEFT JOIN nation n ON rg.r_regionkey = n.n_regionkey
LEFT JOIN PartPriceSummary ph ON n.n_nationkey = ph.p_partkey
LEFT JOIN TopSuppliers ts ON ts.total_sales IS NOT NULL
LEFT JOIN CustomerStats cs ON cs.order_count > 0
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE rg.r_name IS NOT NULL
ORDER BY rg.r_name, total_supplycost DESC, ts.total_sales DESC;
