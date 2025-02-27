WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        s.s_suppkey
),
NullStatus AS (
    SELECT 
        s.s_name,
        CASE 
            WHEN COUNT(DISTINCT l.l_orderkey) > 0 THEN 'Has Orders'
            ELSE 'No Orders'
        END AS order_status,
        SUM(l.l_discount) AS total_discount,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        supplier s
    LEFT JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    r.r_name, 
    ns.order_status,
    ns.total_discount,
    ns.total_quantity,
    ss.avg_supply_cost,
    ss.total_available_quantity,
    ro.net_revenue,
    ro.revenue_rank
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    NullStatus ns ON s.s_name = ns.s_name
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'F' 
          AND o.o_orderkey IS NOT NULL 
          AND o.o_totalprice IS NOT NULL
    )
WHERE 
    (ns.order_status = 'Has Orders' OR ss.avg_supply_cost < (SELECT AVG(avg_supply_cost) FROM SupplierStats))
    AND (ro.net_revenue IS NOT NULL OR ns.total_discount > 0)
ORDER BY 
    r.r_name, ns.total_quantity DESC;
