WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS adjusted_order_value,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATEADD(month, -6, GETDATE()) AND GETDATE()
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    COUNT(DISTINCT fo.o_orderkey) AS num_orders,
    SUM(fo.adjusted_order_value) AS total_order_value,
    AVG(ss.total_supply_cost) AS average_supplier_cost,
    MAX(oss.total_line_price) AS highest_line_price
FROM 
    CustomerOrders cs
JOIN 
    FilteredOrders fo ON cs.c_custkey = fo.o_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.total_parts > 0
LEFT JOIN 
    OrderLineStats oss ON fo.o_orderkey = oss.o_orderkey
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
GROUP BY 
    cs.c_name, ss.s_name
HAVING 
    COUNT(DISTINCT fo.o_orderkey) > 1
ORDER BY 
    total_order_value DESC, customer_name;
