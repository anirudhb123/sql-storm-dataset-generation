WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank_total
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemMetrics AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey, c.c_name
)
SELECT 
    r.r_name,
    COALESCE(cos.total_spent, 0) AS customer_total_spent,
    COALESCE(lm.total_line_items, 0) AS line_items_count,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    AVG(sd.total_supply_cost) AS average_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN 
    LineItemMetrics lm ON sd.s_suppkey = lm.l_orderkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_totalprice > 100)
LEFT JOIN 
    CustomerOrderSummary cos ON c.c_custkey = cos.c_custkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, cos.total_spent, lm.total_line_items
HAVING 
    AVG(sd.total_supply_cost) > 200
ORDER BY 
    r.r_name;
