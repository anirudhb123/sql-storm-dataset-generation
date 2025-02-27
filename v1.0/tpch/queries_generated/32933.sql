WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 
           NULL::integer AS parent_regionkey, 
           r_name AS full_path
    FROM region
    WHERE r_regionkey IS NOT NULL
    
    UNION ALL
    
    SELECT r.r_regionkey, r.r_name, 
           rh.r_regionkey AS parent_regionkey,
           rh.full_path || ' -> ' || r.r_name
    FROM region r
    INNER JOIN RegionHierarchy rh ON r.r_regionkey IS NOT NULL
    WHERE r.r_regionkey != rh.parent_regionkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)

SELECT 
    rh.full_path AS region_path,
    rs.s_name AS supplier_name,
    ro.total_sales AS recent_sales,
    CASE 
        WHEN ro.total_sales IS NULL THEN 'No Orders'
        ELSE 'Ordered'
    END AS order_status
FROM RegionHierarchy rh
LEFT JOIN RankedSuppliers rs ON rs.rank_by_acctbal = 1
LEFT JOIN RecentOrders ro ON rs.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 15 AND p.p_retailprice < 200
)
WHERE rs.s_acctbal > 1000
ORDER BY rh.full_path, rs.s_name;
