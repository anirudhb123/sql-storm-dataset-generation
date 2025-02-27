WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal * 0.5
),
TotalOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, tv.total_value
    FROM orders o
    JOIN TotalOrderValue tv ON o.o_orderkey = tv.o_orderkey
    WHERE tv.total_value > 50000
),
SupplierNation AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT
    rh.s_name,
    rh.s_acctbal,
    n.n_name AS nation,
    hv.total_value,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY rh.s_acctbal DESC) AS rank
FROM SupplierHierarchy rh
JOIN HighValueOrders hv ON hv.o_orderkey IN (
    SELECT DISTINCT l_orderkey
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
)
JOIN SupplierNation n ON rh.s_nationkey = n.n_nationkey
WHERE n.supplier_count > 1
ORDER BY rank, rh.s_acctbal DESC;
