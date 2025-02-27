WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
NationRevenue AS (
    SELECT n.n_nationkey, SUM(o.o_totalprice) AS nation_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey
),
FinalReport AS (
    SELECT n.n_name, nr.nation_revenue, COUNT(DISTINCT o.o_orderkey) AS order_count,
           COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_discount ELSE 0 END), 0) AS total_returns
    FROM nation n
    LEFT JOIN NationRevenue nr ON n.n_nationkey = nr.n_nationkey
    LEFT JOIN orders o ON o.o_orderstatus = 'O'
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY n.n_name, nr.nation_revenue
)
SELECT fh.s_name, fr.n_name, fr.nation_revenue, fr.order_count, fr.total_returns
FROM SupplierHierarchy fh
JOIN FinalReport fr ON fr.n_name IN (
    SELECT n.n_name
    FROM nation n
    WHERE n.n_nationkey = fh.s_nationkey
)
WHERE fh.level = 2
ORDER BY fr.nation_revenue DESC, fr.order_count ASC;
