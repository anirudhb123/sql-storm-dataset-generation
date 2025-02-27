WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 100)
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING total_revenue > 50000
),
NationSales AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, ns.total_sales, COUNT(DISTINCT hp.p_partkey) AS high_value_parts,
       SUM(hv.total_revenue) AS high_value_revenues
FROM region r
LEFT JOIN NationSales ns ON r.r_regionkey = ns.n_nationkey
LEFT JOIN RankedParts hp ON hp.price_rank < 10
LEFT JOIN HighValueOrders hv ON ns.n_name = hv.o_orderkey
GROUP BY r.r_name, ns.total_sales
HAVING SUM(COALESCE(hv.total_revenue, 0)) > 1000000;
