WITH CustomerOrderDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT CONCAT('Order ', o.o_orderkey, ' placed on ', o.o_orderdate, ' with total ', o.o_totalprice), '; ') AS order_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        STRING_AGG(DISTINCT CONCAT('Part ', p.p_partkey, ' of type ', p.p_type, ' priced at ', p.p_retailprice), '; ') AS parts_offered
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    cod.c_custkey, 
    cod.c_name, 
    cod.num_orders, 
    cod.total_spent, 
    cod.order_summary, 
    spd.s_suppkey,
    spd.s_name, 
    spd.total_supply_value, 
    spd.parts_offered
FROM 
    CustomerOrderDetails cod
JOIN 
    SupplierPartDetails spd ON cod.num_orders > 5 AND spd.total_supply_value > 10000
ORDER BY 
    cod.total_spent DESC, 
    spd.total_supply_value DESC;
