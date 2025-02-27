WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_acctbal AS customer_balance,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.customer_name,
        ro.o_totalprice,
        ro.o_orderdate,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        ro.order_rank <= 5
)
SELECT 
    to.customer_name,
    SUM(to.revenue) AS total_revenue,
    COUNT(to.o_orderkey) AS total_orders,
    AVG(to.ps_supplycost) AS avg_supply_cost,
    MAX(to.o_totalprice) AS max_order_value
FROM 
    TopOrders to
GROUP BY 
    to.customer_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
