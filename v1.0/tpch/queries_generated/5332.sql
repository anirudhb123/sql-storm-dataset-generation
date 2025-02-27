WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        r.r_name AS region_name
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.region_name,
    s.s_name,
    SUM(o.order_value) AS total_recent_orders
FROM 
    HighCostSuppliers s
JOIN 
    RecentOrders o ON s.s_suppkey = o.o_orderkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    r.region_name, s.s_name
ORDER BY 
    total_recent_orders DESC
LIMIT 10;
