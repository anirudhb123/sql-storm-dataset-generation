WITH SupplierPartStats AS (
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
), CustomerOrderStats AS (
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
), ProductLineStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(l.l_extendedprice) AS avg_price,
        COUNT(DISTINCT l.l_orderkey) AS total_orders_linked
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    s.s_name,
    cs.c_name,
    ps.p_name,
    ps.avg_price,
    cs.total_orders,
    cs.total_spent,
    sup.total_avail_qty,
    sup.total_supply_value
FROM 
    CustomerOrderStats cs
JOIN 
    SupplierPartStats sup ON cs.total_orders >= 10
JOIN 
    ProductLineStats ps ON ps.total_orders_linked > 5
ORDER BY 
    total_spent DESC, sup.total_supply_value DESC
LIMIT 50;
