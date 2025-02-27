WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
    UNION ALL
    SELECT oh.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerWithBalance AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
HighestSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal = (SELECT MAX(s2.s_acctbal) FROM supplier s2)
)
SELECT DISTINCT
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    r.r_name,
    h.level
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN SupplierCost sc ON l.l_partkey = sc.ps_partkey
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey)
LEFT JOIN HighestSuppliers hs ON c.c_custkey = hs.s_suppkey
JOIN OrderHierarchy h ON h.o_orderkey = o.o_orderkey
WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY c.c_custkey, c.c_name, r.r_name, h.level
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY revenue DESC;
