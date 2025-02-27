WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_nationkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_custkey
)

SELECT 
    cr.region_name,
    ss.s_name,
    COALESCE(SUM(od.total_order_value), 0) AS total_order_value,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS customer_count
FROM 
    CustomerRegion cr
LEFT JOIN 
    OrderDetails od ON cr.c_custkey = od.c_custkey
LEFT JOIN 
    SupplierStats ss ON ss.total_available > 0
GROUP BY 
    cr.region_name, ss.s_name
HAVING 
    total_order_value > 10000 OR total_supply_cost > 50000
ORDER BY 
    cr.region_name, total_order_value DESC;
