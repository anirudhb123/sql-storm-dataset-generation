WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), OrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), ItemStats AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity_sold,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name,
    ss.s_name AS supplier_name,
    os.c_name AS customer_name,
    iss.total_quantity_sold,
    iss.total_revenue,
    ss.total_available_quantity,
    ss.total_supply_cost,
    os.total_orders,
    os.total_order_value
FROM 
    part p
JOIN 
    SupplierStats ss ON EXISTS (
        SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey AND ps.ps_suppkey = ss.s_suppkey
    )
JOIN 
    ItemStats iss ON iss.l_partkey = p.p_partkey
JOIN 
    OrderStats os ON os.total_orders > 10
ORDER BY 
    iss.total_revenue DESC, 
    ss.total_supply_cost ASC
LIMIT 100;
