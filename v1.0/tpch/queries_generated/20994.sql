WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE '%land%')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_nationkey
),
PartSubtotals AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size IS NOT NULL
    GROUP BY ps.ps_partkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
)
SELECT 
    p.p_name,
    COALESCE(ps.total_avail_qty, 0) AS total_available,
    ps.total_supply_cost,
    r.r_name AS region_name,
    COUNT(DISTINCT CASE WHEN lo.l_returnflag = 'R' THEN lo.l_orderkey END) AS return_count,
    SUM(CASE WHEN lo.l_discount BETWEEN 0.05 AND 0.20 THEN lo.l_extendedprice * (1 - lo.l_discount) ELSE 0 END) AS discounted_sales
FROM 
    part p
LEFT JOIN 
    PartSubtotals ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    nation n ON p.p_mfgr = n.n_name
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem lo ON p.p_partkey = lo.l_partkey
WHERE 
    (p.p_retailprice > 100 OR p.p_comment IS NULL)
    AND (p.p_size BETWEEN 10 AND 100 OR p.p_type LIKE '%metal%')
    AND EXISTS (SELECT 1 FROM RecentOrders o WHERE o.o_orderkey = lo.l_orderkey AND o.o_totalprice < 500)
GROUP BY 
    p.p_name, ps.total_avail_qty, ps.total_supply_cost, r.r_name
HAVING 
    SUM(lo.l_quantity) IS NOT NULL OR COUNT(lo.l_orderkey) > 0
ORDER BY 
    total_available DESC, region_name, p.p_name;
