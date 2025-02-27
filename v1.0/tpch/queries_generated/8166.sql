WITH CustomerOrderSummary AS (
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
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS total_parts, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
ProductCategory AS (
    SELECT 
        p.p_partkey, 
        p.p_type, 
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    GROUP BY 
        p.p_partkey, p.p_type
)
SELECT 
    co.c_name AS customer_name, 
    co.total_orders, 
    co.total_spent, 
    sp.s_name AS supplier_name, 
    sp.total_parts, 
    sp.total_supply_cost, 
    pc.p_type AS product_type, 
    pc.avg_price
FROM 
    CustomerOrderSummary co
JOIN 
    SupplierPartDetails sp ON co.total_orders > 0
JOIN 
    ProductCategory pc ON pc.avg_price > 50.00
WHERE 
    co.total_spent > 1000
ORDER BY 
    co.total_spent DESC, sp.total_supply_cost ASC
LIMIT 100;
