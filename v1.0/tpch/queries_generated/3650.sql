WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
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
PartPriceChange AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0
            ELSE ROUND((p.p_retailprice * 1.1), 2)
        END AS new_price
    FROM 
        part p
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    ps.total_available_qty,
    ps.total_supply_value,
    co.total_orders,
    co.total_spent,
    pp.p_name,
    pp.new_price
FROM 
    SupplierSummary ps
FULL OUTER JOIN 
    CustomerOrders co ON co.total_orders > 5 OR ps.total_supply_value > 10000
CROSS JOIN 
    PartPriceChange pp
WHERE 
    (co.total_spent IS NULL OR co.total_spent > 500) 
    AND pp.new_price IS NOT NULL
ORDER BY 
    co.total_spent DESC NULLS LAST, 
    ps.total_supply_value DESC;
