WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
FinalResults AS (
    SELECT n.n_name AS nation, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY n.n_name, p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
CustomerBalance AS (
    SELECT c.c_custkey, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'No balance'
               WHEN c.c_acctbal < 100 THEN 'Low balance'
               WHEN c.c_acctbal BETWEEN 100 AND 1000 THEN 'Medium balance'
               ELSE 'High balance'
           END AS balance_category
    FROM customer c
),
JoinedData AS (
    SELECT fr.nation, fr.p_name, fr.revenue, cb.balance_category
    FROM FinalResults fr
    LEFT JOIN CustomerBalance cb ON fr.revenue > cb.c_acctbal
)
SELECT j.nation, j.p_name, j.revenue, j.balance_category
FROM JoinedData j
WHERE j.revenue > 100000
ORDER BY j.revenue DESC;

