WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1 
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as rnk
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
),
LineItemAnalysis AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue, 
           COUNT(DISTINCT li.l_suppkey) AS supplier_count
    FROM lineitem li
    WHERE li.l_shipdate IS NOT NULL
    GROUP BY li.l_orderkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           CASE WHEN ps.ps_availqty IS NULL THEN 'Unavailable' ELSE 'Available' END AS availability
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    p.p_name,
    r.region_name,
    COALESCE(ra.total_revenue, 0) AS total_revenue
FROM part p
JOIN PartSupplierInfo psi ON p.p_partkey = psi.p_partkey
LEFT JOIN RecentOrders ro ON ro.o_orderkey = (SELECT li.l_orderkey FROM lineitem li WHERE li.l_partkey = p.p_partkey LIMIT 1)
LEFT JOIN (SELECT n.n_regionkey, n.n_name AS region_name FROM nation n) r ON r.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%West%')
LEFT JOIN LineItemAnalysis la ON la.l_orderkey = ro.o_orderkey
WHERE psi.availability = 'Available' AND 
      (ro.o_orderstatus <> 'F' OR ro.o_orderstatus IS NULL)
ORDER BY total_revenue DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
