WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerStats AS (
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
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    coalesce(cs.c_name, 'Unknown Customer') AS customer_name,
    coalesce(os.o_orderkey, 0) AS order_key,
    os.o_orderdate,
    os.o_totalprice,
    si.s_name AS supplier_name,
    si.total_supply_value,
    ls.total_line_value,
    CASE 
        WHEN os.o_orderstatus = 'F' THEN 'Completed'
        ELSE 'Pending'
    END AS order_status,
    DENSE_RANK() OVER (ORDER BY os.o_totalprice DESC) AS price_rank
FROM 
    RankedOrders os
FULL OUTER JOIN 
    CustomerStats cs ON os.o_orderkey = cs.total_orders
LEFT JOIN 
    SupplierInfo si ON si.total_supply_value IS NOT NULL
LEFT JOIN 
    LineItemDetails ls ON ls.l_orderkey = os.o_orderkey
WHERE 
    (os.o_orderkey IS NOT NULL OR cs.c_custkey IS NOT NULL)
    AND (si.total_supply_value IS NOT NULL OR ls.total_line_value IS NOT NULL)
ORDER BY 
    order_status, customer_name, os.o_orderdate DESC;
