WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
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
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_shipdate,
        RANK() OVER(PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
)

SELECT 
    cs.c_custkey,
    cs.c_name,
    ss.s_suppkey,
    ss.s_name,
    SUM(lid.l_extendedprice * (1 - lid.l_discount)) AS revenue_after_discount,
    COALESCE(st.total_supply_value, 0) AS total_supply_value,
    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(co.total_spent, 0) AS total_spent
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem lid ON co.c_custkey = lid.l_orderkey
LEFT JOIN 
    SupplierStats ss ON lid.l_suppkey = ss.s_suppkey
LEFT JOIN 
    SupplierStats st ON ss.s_suppkey = st.s_suppkey
WHERE 
    (co.total_orders > 5 OR co.total_spent > 1000)
    AND lid.l_quantity > 10
GROUP BY 
    cs.c_custkey, cs.c_name, ss.s_suppkey, ss.s_name
HAVING 
    SUM(lid.l_extendedprice * (1 - lid.l_discount)) > 5000
ORDER BY 
    revenue_after_discount DESC;
