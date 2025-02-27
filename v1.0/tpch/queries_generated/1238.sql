WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), HighCostSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        r.r_name, 
        r.r_comment
    FROM 
        RankedSuppliers s
    JOIN 
        region r ON s.s_nationkey = r.r_regionkey 
    WHERE 
        total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
    AND 
        supplier_rank <= 5
), RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    r.s_name AS supplier_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.total_order_value) AS avg_order_value,
    SUM(COALESCE(o.total_order_value, 0)) AS sum_order_value
FROM 
    HighCostSuppliers r
LEFT JOIN 
    RecentOrders o ON r.s_suppkey = o.o_custkey
GROUP BY 
    r.s_suppkey, r.s_name, r.r_name
HAVING 
    SUM(COALESCE(o.total_order_value, 0)) > 100000
ORDER BY 
    avg_order_value DESC;
