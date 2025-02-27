WITH RECURSIVE CustomerOrders AS (
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
PartSupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice) > 1000
)
SELECT 
    c.c_name,
    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(co.total_spent, 0.00) AS total_spent,
    p.p_name AS top_product,
    ps.total_supply_cost,
    CASE 
        WHEN ps.total_supply_cost IS NULL THEN 'No suppliers available'
        ELSE 'Suppliers available'
    END AS supplier_status
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    TopProducts p ON p.rank = 1
JOIN 
    PartSupplierCost ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    nation n ON n.n_nationkey = c.c_nationkey
WHERE 
    n.n_name IS NOT NULL
ORDER BY 
    total_spent DESC NULLS LAST;
