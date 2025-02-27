WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, 
        c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice
)
SELECT 
    c.c_name AS customer_name,
    sp.s_name AS supplier_name,
    pd.p_name AS part_name,
    pd.total_quantity_sold,
    pd.p_retailprice,
    sp.total_supply_cost,
    (pd.p_retailprice * pd.total_quantity_sold) AS revenue_generated,
    co.total_order_value
FROM 
    CustomerOrders co
JOIN 
    SupplierParts sp ON co.c_custkey = (SELECT c_custkey FROM customer WHERE c_name = sp.s_name LIMIT 1)
JOIN 
    PartDetails pd ON pd.total_quantity_sold > 1000
WHERE 
    sp.total_supply_cost < co.total_order_value
ORDER BY 
    revenue_generated DESC
LIMIT 10;
