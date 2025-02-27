WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ProductStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold,
        AVG(l.l_extendedprice) AS average_price
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ss.s_name AS Supplier_Name,
    css.c_name AS Customer_Name,
    ps.p_name AS Product_Name,
    ss.total_parts,
    css.total_orders,
    css.total_spent,
    ps.total_quantity_sold,
    ps.average_price,
    ss.total_supply_cost
FROM 
    SupplierStats ss
JOIN 
    CustomerOrderStats css ON ss.total_parts > 10 AND css.total_orders > 5
JOIN 
    ProductStats ps ON ps.total_quantity_sold > 100
ORDER BY 
    ss.total_supply_cost DESC, 
    css.total_spent DESC, 
    ps.average_price ASC
LIMIT 100;
