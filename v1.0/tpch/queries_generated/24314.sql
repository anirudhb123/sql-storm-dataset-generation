WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           (SELECT AVG(l.l_extendedprice) 
            FROM lineitem l 
            WHERE l.l_partkey = p.p_partkey) AS avg_ext_price
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
FilteredOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_orderkey
)
SELECT 
    ns.n_name AS nation_name,
    COALESCE(SUM(o.total_sales), 0) AS total_ordered_sales,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts_sold,
    s.s_name AS supplier_name,
    AVG(hp.avg_ext_price) AS avg_price_for_high_value_parts
FROM nation ns
LEFT JOIN FilteredOrders o ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O'))
LEFT JOIN RankedSuppliers s ON ns.n_nationkey = (SELECT n.n_nationkey FROM supplier s1 JOIN nation n ON s1.s_nationkey = n.n_nationkey WHERE s1.s_acctbal > 1000)
LEFT JOIN HighValueParts hp ON hp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps JOIN supplier s2 ON ps.ps_suppkey = s2.s_suppkey WHERE s2.s_acctbal > 500)
GROUP BY ns.n_name, s.s_name
HAVING COUNT(DISTINCT p.p_partkey) > 1
ORDER BY total_ordered_sales DESC, nation_name;
