WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        o.o_totalprice, 
        1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        o.o_totalprice, 
        oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
OrderSummary AS (
    SELECT 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND l.l_shipdate IS NOT NULL
    GROUP BY c.c_name
    HAVING COUNT(o.o_orderkey) > 10
),
SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
RegionRevenue AS (
    SELECT 
        r.r_name,
        SUM(os.total_revenue) AS total_region_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN OrderSummary os ON c.c_name = os.c_name
    GROUP BY r.r_name
)
SELECT 
    rh.o_orderkey,
    rh.o_orderstatus,
    rh.o_orderdate,
    rh.level,
    COALESCE(SUM(sm.supplier_value), 0) AS total_supplier_value,
    rr.total_region_revenue
FROM OrderHierarchy rh
LEFT JOIN SupplierMetrics sm ON rh.o_orderkey = sm.s_suppkey
LEFT JOIN RegionRevenue rr ON rr.total_region_revenue > 0
GROUP BY rh.o_orderkey, rh.o_orderstatus, rh.o_orderdate, rh.level, rr.total_region_revenue
ORDER BY rh.o_orderdate DESC, rh.o_orderkey;
