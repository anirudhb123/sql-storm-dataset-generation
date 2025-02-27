WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerTotalOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count,
        CASE 
            WHEN SUM(o.o_totalprice) > 1000 THEN 'High Value'
            ELSE 'Regular Value'
        END AS customer_status
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT cd.c_custkey) AS total_customers,
    COALESCE(SUM(s.total_supply_cost), 0) AS total_supply_cost,
    AVG(cd.total_orders) AS avg_orders,
    MAX(cd.order_count) AS max_orders,
    CASE 
        WHEN COUNT(DISTINCT cd.c_custkey) = 0 THEN 'No Customers'
        ELSE 'Customers Available'
    END AS customer_availability
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cd ON n.n_nationkey = cd.c_nationkey
LEFT JOIN 
    SupplierDetails s ON n.n_nationkey = s.s_nationkey
GROUP BY 
    r.r_name
HAVING 
    SUM(cd.total_orders) IS NOT NULL
ORDER BY 
    total_customers DESC;
