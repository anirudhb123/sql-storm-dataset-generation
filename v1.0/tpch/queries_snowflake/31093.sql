WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),

PartOrders AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY p.p_partkey
),

RankedParts AS (
    SELECT p.p_partkey, p.p_name, po.total_revenue,
           RANK() OVER (ORDER BY po.total_revenue DESC) AS revenue_rank
    FROM part p
    LEFT JOIN PartOrders po ON p.p_partkey = po.p_partkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    rp.p_name AS part_name,
    rp.total_revenue,
    rp.revenue_rank,
    CASE 
        WHEN rp.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM RankedParts rp
JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name LIKE '%north%'
  AND rp.revenue_rank <= 10
  AND EXISTS (SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_nationkey = s.s_nationkey)
ORDER BY total_revenue DESC, region_name, nation_name;