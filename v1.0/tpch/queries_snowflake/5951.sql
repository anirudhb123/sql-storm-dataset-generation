
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT
        r.n_name AS nation_name,
        COUNT(ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_revenue,
        AVG(ro.o_totalprice) AS avg_order_value
    FROM 
        RankedOrders ro
    JOIN 
        nation r ON ro.c_nationkey = r.n_nationkey
    WHERE 
        ro.order_rank <= 5
    GROUP BY 
        r.n_name
),
SupplierStats AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    t.nation_name,
    t.total_orders,
    t.total_revenue,
    t.avg_order_value,
    ss.total_supply_cost
FROM 
    TopOrders t
LEFT JOIN 
    SupplierStats ss ON ss.ps_partkey = (SELECT r.r_regionkey FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = t.nation_name LIMIT 1) LIMIT 1)
ORDER BY 
    t.total_revenue DESC, 
    t.nation_name ASC;
