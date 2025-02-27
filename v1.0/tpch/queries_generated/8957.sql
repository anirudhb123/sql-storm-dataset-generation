WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
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
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    ss.s_name AS supplier_name,
    ss.total_available,
    ss.total_cost,
    ld.total_line_price
FROM 
    CustomerOrders cs
JOIN 
    SupplierStats ss ON ss.total_available > 1000
JOIN 
    LineItemDetails ld ON ld.total_line_price > 5000
WHERE 
    cs.total_spent > 10000
ORDER BY 
    cs.total_spent DESC, ss.total_cost ASC
LIMIT 100;
