
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
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
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    CASE 
        WHEN r.order_rank = 1 THEN 'Top Order' 
        ELSE 'Other Order' 
    END AS order_category,
    s.s_name,
    COALESCE(fs.order_count, 0) AS frequent_customer_count
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierStats s ON r.o_orderkey = s.s_suppkey
LEFT JOIN 
    FrequentCustomers fs ON fs.c_custkey = r.o_orderkey
WHERE 
    r.total_revenue >= 1000.00
ORDER BY 
    r.total_revenue DESC, r.o_orderdate;
