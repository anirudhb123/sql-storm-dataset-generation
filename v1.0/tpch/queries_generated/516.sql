WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
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
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    ss.total_available,
    ss.average_supply_cost,
    lis.revenue,
    lis.line_count
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON cs.total_orders > 0
LEFT JOIN 
    LineItemStats lis ON cs.total_orders = 0
WHERE 
    cs.total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerOrders
    )
ORDER BY 
    cs.total_spent DESC, 
    ss.average_supply_cost ASC
FETCH FIRST 100 ROWS ONLY;
