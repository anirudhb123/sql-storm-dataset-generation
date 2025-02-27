WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_nationkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
CombinedStats AS (
    SELECT 
        r.region_name,
        s.total_available_quantity,
        s.supplier_count,
        co.total_orders,
        co.total_revenue
    FROM 
        RegionStats r
    LEFT JOIN 
        CustomerOrders co ON r.region_name = (
            SELECT n.r_name 
            FROM nation n 
            WHERE n.n_nationkey = co.c_nationkey
            LIMIT 1
        )
    LEFT JOIN 
        (SELECT n.n_nationkey, COUNT(*) AS supplier_count 
         FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey GROUP BY n.n_nationkey) AS s ON co.c_nationkey = s.n_nationkey
)
SELECT 
    cs.region_name,
    cs.total_available_quantity,
    cs.supplier_count,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_revenue, 0.00) AS total_revenue,
    (cs.total_orders / NULLIF(cs.total_available_quantity, 0)) AS order_per_avail_qty_ratio
FROM 
    CombinedStats cs
ORDER BY 
    cs.total_revenue DESC, cs.total_orders DESC;
