WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPerformance AS (
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
)

SELECT 
    c.c_name AS customer_name,
    c.total_spent AS customer_spending,
    hav.total_revenue AS high_value_order_revenue,
    sp.total_supply_cost AS supplier_cost
FROM 
    CustomerSpending c
LEFT JOIN 
    HighValueOrders hav ON c.total_spent > 10000
LEFT JOIN 
    SupplierPerformance sp ON c.total_spent <= sp.total_supply_cost
WHERE 
    c.total_spent > (SELECT AVG(total_spent) FROM CustomerSpending)
ORDER BY 
    c.total_spent DESC;
