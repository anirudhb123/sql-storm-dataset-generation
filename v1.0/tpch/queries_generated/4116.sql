WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    c.c_name AS customer_name,
    c.total_spent,
    s.s_name AS supplier_name,
    s.avg_supply_cost,
    CASE 
        WHEN c.total_orders > 10 THEN 'High'
        WHEN c.total_orders BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS order_value_category
FROM 
    CustomerOrderSummary c
FULL OUTER JOIN 
    SupplierPartSummary s ON c.total_spent IS NOT NULL AND s.avg_supply_cost IS NOT NULL
WHERE 
    c.total_spent IS NOT NULL OR s.avg_supply_cost IS NOT NULL
ORDER BY 
    c.total_spent DESC NULLS LAST,
    s.avg_supply_cost ASC NULLS FIRST;
