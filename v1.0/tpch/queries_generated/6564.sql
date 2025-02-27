WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        CASE 
            WHEN o.o_orderdate < '1995-01-01' THEN 'Before 1995'
            WHEN o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '2000-01-01' THEN '1995-1999'
            ELSE '2000 and After'
        END AS order_period
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierSummary AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    os.order_period,
    SUM(os.total_revenue) AS total_revenue_by_period,
    ss.suppkey,
    ss.total_supply_cost,
    ss.part_count,
    cr.c_custkey,
    cr.c_name,
    cr.customer_revenue
FROM 
    OrderSummary os
JOIN 
    SupplierSummary ss ON os.o_orderkey = ss.ps_suppkey
JOIN 
    CustomerRevenue cr ON os.o_orderkey = cr.c_custkey
GROUP BY 
    os.order_period, ss.suppkey, ss.total_supply_cost, ss.part_count, cr.c_custkey, cr.c_name
ORDER BY 
    order_period, total_revenue_by_period DESC, customer_revenue DESC;
