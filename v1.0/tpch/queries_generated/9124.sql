WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_avail_qty,
        ss.total_supply_value,
        NTILE(10) OVER (ORDER BY ss.total_supply_value DESC) AS tier
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.tier,
    ts.s_name AS supplier_name,
    ts.total_avail_qty AS supplier_availability,
    ts.total_supply_value AS supplier_value,
    co.c_name AS customer_name,
    co.order_count AS customer_order_count,
    co.total_spent AS customer_total_spent,
    co.avg_order_value AS customer_avg_order_value
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrders co ON ts.tier = CASE 
                                        WHEN co.total_spent > 10000 THEN 1
                                        WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 2
                                        ELSE 3
                                    END
ORDER BY 
    ts.total_supply_value DESC, co.total_spent DESC;
