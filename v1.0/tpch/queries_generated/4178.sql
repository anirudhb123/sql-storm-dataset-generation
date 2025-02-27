WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_customer AS o_customer,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        CASE 
            WHEN c.c_acctbal < 1000 THEN 'Low Balance'
            WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
            ELSE 'High Balance' 
        END AS balance_category
    FROM 
        customer c
),
AggregateLineItems AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.order_rank,
    c.c_name,
    c.balance_category,
    s.s_name AS supplier_name,
    s.total_available_quantity,
    li.total_lines,
    li.total_revenue
FROM 
    RankedOrders o
JOIN 
    CustomerSummary c ON o.o_customer = c.c_custkey
LEFT JOIN 
    SupplierDetails s ON s.total_available_quantity > 0
JOIN 
    AggregateLineItems li ON li.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'F' AND 
    (s.total_supply_cost IS NULL OR s.total_supply_cost < 500.00)
ORDER BY 
    o.o_totalprice DESC
LIMIT 100;
