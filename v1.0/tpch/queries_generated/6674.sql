WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice) AS total_line_value,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    os.total_line_value AS total_value_per_order,
    cs.total_order_value AS customer_total_spent,
    ss.total_supply_cost AS supplier_total_cost,
    cs.num_orders AS number_of_orders,
    os.line_item_count AS line_item_count,
    os.first_ship_date,
    os.last_ship_date
FROM 
    CustomerStats cs
JOIN 
    OrderStats os ON cs.c_custkey = os.o_custkey
JOIN 
    SupplierStats ss ON ss.num_parts > 5
ORDER BY 
    customer_total_spent DESC, 
    supplier_total_cost DESC;
