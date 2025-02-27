WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.level * 100 AND sh.level < 3
),
TopPartData AS (
    SELECT p.p_partkey, 
           p.p_name,
           p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty 
                       FROM partsupp ps WHERE ps.ps_supplycost < 100.00)
),
FilteredOrders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           SUM(l.l_discount * l.l_extendedprice) AS total_discounted_price,
           COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_totalprice
),
FinalReport AS (
    SELECT r.r_name AS region_name,
           n.n_name AS nation_name,
           COUNT(DISTINCT c.c_custkey) AS total_customers,
           SUM(od.total_discounted_price) AS sum_discounted_orders,
           STRING_AGG(sp.s_name, ', ') AS top_suppliers
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN FilteredOrders od ON c.c_custkey = od.o_orderkey
    LEFT JOIN SupplierHierarchy sp ON sp.s_nationkey = n.n_nationkey
    WHERE EXISTS (SELECT 1 FROM TopPartData tp WHERE tp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey))
    GROUP BY r.r_name, n.n_name
    HAVING COUNT(DISTINCT c.c_custkey) > 10
)
SELECT *
FROM FinalReport
ORDER BY sum_discounted_orders DESC NULLS LAST;
