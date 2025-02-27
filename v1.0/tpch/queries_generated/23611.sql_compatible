
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
MaxOrders AS (
    SELECT 
        o.o_custkey,
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        orders o
    WHERE 
        o.o_orderstatus != 'F' OR o.o_orderstatus IS NULL
    GROUP BY 
        o.o_custkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        m.max_order_value,
        RANK() OVER (ORDER BY m.max_order_value DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        MaxOrders m ON c.c_custkey = m.o_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT co.c_custkey) AS unique_customers,
    SUM(COALESCE(rs.total_supply_cost, 0)) AS total_cost,
    MAX(co.order_rank) AS highest_order_rank,
    STRING_AGG(co.c_name, ', ') AS customer_names
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rn = 1
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey
WHERE 
    (r.r_name LIKE 'A%' OR r.r_name IS NULL)
    AND (co.max_order_value IS NOT NULL OR rs.total_supply_cost IS NOT NULL)
GROUP BY 
    r.r_name
ORDER BY 
    total_cost DESC, unique_customers DESC;
