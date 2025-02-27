WITH SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        oi.o_orderkey,
        oi.o_orderdate,
        oi.total_revenue,
        ROW_NUMBER() OVER (ORDER BY oi.total_revenue DESC) AS rn
    FROM 
        OrderInfo oi
    WHERE 
        oi.total_revenue > 10000
)
SELECT 
    p.p_partkey, 
    p.p_name,
    COALESCE(sd.total_availqty, 0) AS available_quantity,
    COALESCE(sd.avg_supplycost, 0) AS average_supply_cost,
    to_char(TO_DATE(o.o_orderdate, 'YYYY-MM-DD'), 'Month') AS order_month,
    oo.total_revenue
FROM 
    part p
LEFT JOIN 
    SupplyDetails sd ON p.p_partkey = sd.ps_partkey
LEFT JOIN 
    TopOrders oo ON oo.o_orderkey IN (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    )
ORDER BY 
    p.p_partkey;
