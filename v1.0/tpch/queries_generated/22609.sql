WITH RECURSIVE shipments AS (
    SELECT 
        l.orderkey, 
        SUM(l.extendedprice * (1 - l.discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY l.orderkey ORDER BY l.shipdate DESC) AS rn
    FROM lineitem l
    WHERE l.returnflag = 'R' OR l.receiptdate IS NOT NULL
    GROUP BY l.orderkey
),
region_summary AS (
    SELECT 
        r.r_name,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COALESCE(SUM(l.quantity), 0) AS total_quantity,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM region r 
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey 
    WHERE (l.shipdate >= CURRENT_DATE - INTERVAL '1 year' OR l.shipdate IS NULL)
    GROUP BY r.r_name
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank,
        CASE 
            WHEN l.l_returnflag IS NULL THEN 'No Return'
            ELSE 'Returned'
        END AS return_status
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.shipdate IS NOT NULL
)
SELECT 
    rs.r_name,
    SUM(rs.total_supplycost) AS total_region_cost,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(CASE WHEN ro.return_status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
    AVG(so.total_revenue) AS average_revenue_per_order
FROM region_summary rs
LEFT JOIN ranked_orders ro ON rs.unique_suppliers > 0
LEFT JOIN shipments so ON ro.o_orderkey = so.orderkey AND so.rn = 1
WHERE rs.total_quantity > 0 
GROUP BY rs.r_name 
HAVING AVG(so.total_revenue) IS NOT NULL OR COUNT(ro.o_orderkey) = 0
ORDER BY total_region_cost DESC, rs.r_name;
