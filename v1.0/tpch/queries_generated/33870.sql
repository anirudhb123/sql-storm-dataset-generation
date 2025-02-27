WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM part p
    WHERE p.p_retailprice > 100
), OrderSummaries AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name AS nation, 
    s.s_name AS supplier_name, 
    rp.p_name AS part_name, 
    rp.rank_by_price, 
    os.total_revenue,
    CASE WHEN os.total_revenue IS NULL THEN 'No Sales' ELSE 'Sales Recorded' END AS sales_status
FROM 
    SupplierHierarchy sh
JOIN 
    supplier s ON sh.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    RankedParts rp ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey LIMIT 1)
LEFT JOIN 
    OrderSummaries os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey LIMIT 1) LIMIT 1)
WHERE 
    n.r_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Americas')
    AND rp.rank_by_price <= 5
ORDER BY 
    total_revenue DESC NULLS LAST, 
    rp.p_name;
