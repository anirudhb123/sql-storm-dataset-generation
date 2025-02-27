WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level
    FROM region
    WHERE r_name LIKE '%North%'
    UNION ALL
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name LIKE '%' || rh.r_name || '%')
    WHERE rh.level < 5
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND s.s_comment NOT ILIKE '%INCORRECT%'
),
AggregatedLineItems AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_partkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
    AND o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= CURRENT_DATE - INTERVAL '1 YEAR'
    )
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size BETWEEN 10 AND 25
),
FinalSelection AS (
    SELECT DISTINCT p.p_name, sp.s_name, sp.ps_supplycost, r.r_name, COALESCE(sup.total_revenue, 0) AS total_revenue
    FROM SupplierPartDetails sp
    LEFT JOIN HighValueSuppliers hv ON sp.ps_suppkey = hv.s_suppkey
    LEFT JOIN RegionHierarchy r ON hv.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
    LEFT JOIN AggregatedLineItems sup ON sp.ps_partkey = sup.l_partkey
    WHERE r.r_name IS NOT NULL
)
SELECT f.p_name, f.s_name, f.ps_supplycost, f.total_revenue, 
       CASE 
           WHEN f.total_revenue IS NULL THEN 'No Revenue' 
           ELSE 'Revenue Exists' 
       END AS revenue_status
FROM FinalSelection f
ORDER BY f.total_revenue DESC NULLS LAST
LIMIT 10;
