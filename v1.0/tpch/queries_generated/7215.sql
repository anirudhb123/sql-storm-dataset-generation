WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    na.n_name AS nation_name,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    SUM(l.total_quantity) AS total_quantity_sold,
    SUM(s.total_supply_cost) AS total_supplier_cost,
    AVG(co.total_order_value) AS avg_order_value
FROM 
    nation na
JOIN 
    customer c ON na.n_nationkey = c.c_nationkey
JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
JOIN 
    orders o ON co.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    SupplierCost s ON l.l_suppkey = s.s_suppkey
WHERE 
    na.n_name IN ('USA', 'Canada')
GROUP BY 
    na.n_name
ORDER BY 
    customer_count DESC, total_quantity_sold DESC;
