WITH RegionalSummary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_name
),
OrderStats AS (
    SELECT 
        o.o_orderstatus AS order_status,
        COUNT(o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderstatus
)
SELECT 
    r.region_name,
    r.total_supply_cost,
    r.total_suppliers,
    r.total_customers,
    o.order_status,
    o.order_count,
    o.total_revenue,
    o.avg_order_value
FROM 
    RegionalSummary r
LEFT JOIN 
    OrderStats o ON r.region_name = (
        SELECT n.r_name 
        FROM nation n 
        JOIN region r ON n.n_regionkey = r.r_regionkey 
        LIMIT 1
    )
ORDER BY 
    r.total_supply_cost DESC, o.order_count DESC;
