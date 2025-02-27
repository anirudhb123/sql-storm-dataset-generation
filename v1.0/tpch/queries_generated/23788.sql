WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(wo.total_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        (SELECT DISTINCT o.o_custkey, ro.total_price 
         FROM RankedOrders ro 
         JOIN orders o ON ro.o_orderkey = o.o_orderkey) wo ON c.c_custkey = wo.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    c.c_custkey,
    c.total_orders,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN c.total_orders IS NULL THEN 'No Orders Yet'
        WHEN c.total_spent > 10000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    CustomerSales c
FULL OUTER JOIN 
    SupplierDetails s ON c.c_custkey = s.s_suppkey
WHERE 
    (c.total_orders IS NOT NULL OR s.total_supply_cost IS NOT NULL)
    AND NOT (c.total_spent IS NULL AND s.total_supply_cost IS NULL)
ORDER BY 
    customer_status DESC, 
    c.c_custkey ASC NULLS LAST;
