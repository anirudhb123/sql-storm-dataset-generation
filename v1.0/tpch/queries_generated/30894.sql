WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(os.total_sales) AS total_nation_sales
    FROM nation n
    LEFT JOIN OrderSummary os ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c 
                                                   WHERE c.c_custkey IN (SELECT o.o_custkey FROM orders o 
                                                                         WHERE o.o_orderkey = os.o_orderkey))
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_partkey, p.p_name, ps.supp_count, ps.avg_supply_cost,
       ns.total_nation_sales, sh.level
FROM PartSummary ps
JOIN NationSales ns ON ps.supplier_count > 5 AND ns.total_nation_sales IS NOT NULL
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = ns.n_nationkey
WHERE (p.p_retailprice > 50 OR EXISTS (SELECT 1 FROM lineitem l 
                                         WHERE l.l_discount > 0.2 
                                         AND l.l_partkey = p.p_partkey))
ORDER BY ns.total_nation_sales DESC, ps.avg_supply_cost ASC;
