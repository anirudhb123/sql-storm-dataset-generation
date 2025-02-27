WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FrequentBuyers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' -- Only considering open orders
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    fs.s_name,
    fs.total_available_quantity,
    fs.average_supply_cost,
    cb.c_name AS frequent_buyer,
    cb.order_count
FROM 
    SupplierSummary fs
FULL OUTER JOIN 
    FrequentBuyers cb ON fs.total_available_quantity > 1000
WHERE 
    fs.total_available_quantity IS NOT NULL OR cb.order_count IS NOT NULL
ORDER BY 
    fs.average_supply_cost DESC NULLS LAST, 
    cb.order_count DESC NULLS LAST;
