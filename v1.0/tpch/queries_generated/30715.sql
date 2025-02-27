WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 100 AND p.p_retailprice < 50.00
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
NationSupplierCounts AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    SUM(fs.ps_supplycost * fs.ps_availqty) AS total_cost,
    COUNT(DISTINCT fh.s_suppkey) AS unique_suppliers,
    AVG(fo.total_order_value) AS average_order_value
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN NationSupplierCounts ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN FilteredParts fs ON fs.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'Manufacturer X')
INNER JOIN SupplierHierarchy fh ON fh.s_nationkey = n.n_nationkey
INNER JOIN RankedOrders fo ON fo.o_orderkey IN 
    (SELECT l.l_orderkey FROM lineitem l WHERE l.l_shipmode = 'TRUCK' AND l.l_returnflag = 'N')
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_cost DESC;
