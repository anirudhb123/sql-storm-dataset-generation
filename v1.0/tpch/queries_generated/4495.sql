WITH RecursiveSupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        r.level + 1
    FROM supplier s
    JOIN RecursiveSupplierInfo r ON s.s_nationkey = r.s_nationkey
    WHERE r.level < 3
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count,
        r.r_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY o.o_orderkey, r.r_name
),
SupplierRevenue AS (
    SELECT 
        r.r_name,
        SUM(od.total_revenue) AS total_revenue_per_region,
        COUNT(DISTINCT od.o_orderkey) AS unique_orders
    FROM OrderDetails od
    LEFT JOIN nation n ON od.r_name = n.n_name
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_name
)
SELECT 
    sr.r_name,
    COALESCE(sr.total_revenue_per_region, 0) AS total_revenue,
    COALESCE(sr.unique_orders, 0) AS order_count,
    COUNT(DISTINCT rsi.s_suppkey) AS supplier_count
FROM SupplierRevenue sr
FULL OUTER JOIN RecursiveSupplierInfo rsi ON sr.r_name = (SELECT r.r_name FROM region r WHERE r.r_regionkey = rsi.s_nationkey)
WHERE sr.total_revenue_per_region > 10000 OR rsi.s_acctbal > 5000
GROUP BY sr.r_name
ORDER BY total_revenue DESC, supplier_count ASC
LIMIT 50;
