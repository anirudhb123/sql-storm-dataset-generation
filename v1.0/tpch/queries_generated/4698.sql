WITH SupplierProfit AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN total_spent > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        CustomerOrders c
    WHERE 
        total_orders > 5
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
)
SELECT 
    s.s_name AS Supplier_Name,
    p.p_name AS Part_Name,
    s.total_supply_cost,
    c.c_name AS Customer_Name,
    c.customer_type,
    CASE 
        WHEN lp.l_shipmode = 'AIR' THEN 'Fast'
        WHEN lp.l_shipmode = 'GROUND' THEN 'Standard'
        ELSE 'Other'
    END AS shipping_category
FROM 
    SupplierProfit s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem lp ON lp.l_partkey = p.p_partkey
LEFT JOIN 
    HighValueCustomers c ON lp.l_orderkey = (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = c.c_custkey
        ORDER BY o.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    s.total_supply_cost > 50000
AND 
    p.p_retailprice IS NOT NULL
ORDER BY 
    total_supply_cost DESC, customer_type ASC;
