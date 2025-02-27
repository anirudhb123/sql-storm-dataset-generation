WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY o.o_orderkey, o.o_custkey
),
SuppliersWithComments AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_type,
        CONCAT('Supplier ', s.s_name, ' provides ', p.p_name) AS supplier_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL
)
SELECT 
    r.s_suppkey, 
    r.s_name, 
    r.s_acctbal,
    coalesce(ro.total_revenue, 0) AS total_revenue_last_6_months,
    coalesce(ro.total_items, 0) AS total_items_last_6_months,
    concat(r.s_name, ' - ', swc.supplier_info) AS personalized_comment 
FROM RankedSuppliers r
LEFT JOIN RecentOrders ro ON ro.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = r.s_suppkey))
LEFT JOIN SuppliersWithComments swc ON r.s_suppkey = swc.s_suppkey
WHERE r.supplier_rank = 1
ORDER BY r.s_acctbal DESC, total_revenue_last_6_months DESC;
