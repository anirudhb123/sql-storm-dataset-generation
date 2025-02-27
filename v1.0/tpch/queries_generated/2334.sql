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
PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name, 
    cos.total_orders, 
    cos.total_spent, 
    ps.p_name, 
    ps.total_available, 
    ps.avg_supply_cost,
    CASE 
        WHEN cos.total_spent > 1000 THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    CustomerOrderSummary cos
FULL OUTER JOIN 
    PartSupplierDetails ps ON cos.c_custkey = ps.p_partkey
WHERE 
    (ps.total_available IS NULL OR ps.total_available > 0)
    AND cos.total_orders IS NOT NULL
ORDER BY 
    cos.total_spent DESC, 
    ps.avg_supply_cost ASC;
