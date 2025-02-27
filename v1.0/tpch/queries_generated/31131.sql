WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT ss.s_suppkey, ss.s_name, ss.s_nationkey, ss.s_acctbal, sh.Level + 1
    FROM supplier ss
    JOIN SupplierHierarchy sh ON ss.s_nationkey = sh.s_nationkey
    WHERE ss.s_acctbal > sh.s_acctbal
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 1000
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS TotalAvailable
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) > 50
),
NationsWithComments AS (
    SELECT n.n_nationkey, n.n_name, CASE WHEN n.n_comment IS NULL OR n.n_comment = '' THEN 'No comment' ELSE n.n_comment END AS Comment
    FROM nation n
),
AggLineItems AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT s.s_name, r.o_orderkey, r.o_totalprice, p.p_name, a.TotalRevenue, n.Comment
FROM SupplierHierarchy s
LEFT JOIN RankedOrders r ON s.s_suppkey = r.o_custkey
JOIN FilteredParts p ON p.p_partkey = r.o_orderkey
LEFT JOIN AggLineItems a ON a.l_partkey = p.p_partkey
JOIN NationsWithComments n ON n.n_nationkey = s.s_nationkey
WHERE (r.o_totalprice > a.TotalRevenue OR a.TotalRevenue IS NULL)
ORDER BY s.s_name, r.o_orderkey, p.p_name;
