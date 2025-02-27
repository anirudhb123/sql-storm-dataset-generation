WITH CustomerOrders AS (
    SELECT 
        c.c_name,
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, c.c_custkey
),
SupplierParts AS (
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
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_price_per_item,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey, l.l_partkey
)

SELECT 
    co.c_name,
    co.total_spent,
    sp.total_available,
    sp.total_cost,
    lis.total_quantity,
    lis.avg_price_per_item,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS rank
FROM 
    CustomerOrders co
LEFT JOIN 
    SupplierParts sp ON sp.total_cost > 1000
LEFT JOIN 
    LineItemStats lis ON co.total_spent > 500 AND lis.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_totalprice > 500)
WHERE 
    co.order_count > 0
ORDER BY 
    co.total_spent DESC, sp.total_available DESC;
