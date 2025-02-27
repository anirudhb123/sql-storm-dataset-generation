WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate,
        o.o_orderpriority,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate,
        o.o_orderpriority,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey AND o.o_orderstatus = 'O'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_expenditure,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_name AS customer_name,
    cs.total_expenditure,
    cs.total_orders,
    s.s_suppkey AS supplier_id,
    ss.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY cs.total_expenditure DESC) AS expenditure_rank
FROM 
    CustomerSummary cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierStats ss ON ss.total_supply_cost IS NOT NULL
WHERE 
    cs.total_expenditure > (SELECT AVG(total_expenditure) FROM CustomerSummary)
ORDER BY 
    cs.total_expenditure DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
