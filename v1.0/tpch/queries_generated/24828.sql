WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_acctbal IS NOT NULL
    WHERE sh.level < 5
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
PartAggregation AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStatistics AS (
    SELECT o.o_orderkey, COUNT(li.l_orderkey) AS lineitem_count, SUM(o.o_totalprice) AS total_price
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
)
SELECT 
    nd.n_name,
    nd.region_name,
    sha.level AS supplier_level,
    pa.total_available_qty,
    os.lineitem_count,
    os.total_price,
    CASE 
        WHEN os.total_price IS NULL THEN 'No Orders'
        WHEN os.total_price > 10000 THEN 'High Value Order'
        ELSE 'Standard Order'
    END AS order_category,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')') ORDER BY s.s_acctbal DESC) AS suppliers
FROM NationDetails nd
LEFT JOIN SupplierHierarchy sha ON nd.n_nationkey = sha.s_nationkey
LEFT JOIN PartAggregation pa ON pa.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON o.o_orderkey = l.l_orderkey WHERE o.o_orderstatus = 'O')
LEFT JOIN OrderStatistics os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nd.n_nationkey))
LEFT JOIN supplier s ON nd.n_nationkey = s.s_nationkey
WHERE nd.supplier_count > 5 
    AND (pa.total_available_qty IS NOT NULL OR os.lineitem_count > 0)
GROUP BY nd.n_name, nd.region_name, sha.level, pa.total_available_qty, os.lineitem_count, os.total_price
ORDER BY nd.n_name, sha.level DESC;
