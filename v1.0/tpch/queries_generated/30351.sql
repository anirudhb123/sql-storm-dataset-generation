WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
PartAndSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, s.s_nationkey
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
)
SELECT p.p_name, ps.ps_availqty, ps.ps_supplycost, sup.s_name, o.o_orderkey, o.total_sales, r.o_orderdate, r.rank
FROM PartAndSupplier ps
LEFT JOIN supplier sup ON ps.s_nationkey = sup.s_nationkey
JOIN HighValueOrders o ON o.o_orderkey = ps.ps_partkey
FULL OUTER JOIN RankedOrders r ON r.o_orderkey = o.o_orderkey
WHERE (ps.ps_availqty IS NOT NULL OR sup.s_name IS NULL)
AND r.rank <= 5
ORDER BY total_sales DESC, ps.ps_supplycost ASC;
