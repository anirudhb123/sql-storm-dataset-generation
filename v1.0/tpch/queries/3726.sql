WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
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
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS rn
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < cast('1998-10-01' as date) - INTERVAL '30 DAY'
),
AveragePrice AS (
    SELECT 
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        LineItemDetails l
)
SELECT 
    cs.total_orders,
    cs.total_spent,
    ss.total_avail_qty,
    ss.total_supply_cost,
    ap.avg_price
FROM 
    CustomerOrderStats cs
JOIN 
    SupplierStats ss ON cs.total_orders > 10
CROSS JOIN 
    AveragePrice ap
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats);