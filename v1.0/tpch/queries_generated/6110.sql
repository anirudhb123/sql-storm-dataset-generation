WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        nation, 
        s_suppkey, 
        s_name, 
        total_supply_cost 
    FROM 
        RankedSuppliers 
    WHERE 
        rnk <= 3
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_comment,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        l.l_linestatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    tos.nation,
    tos.s_name,
    COUNT(DISTINCT ro.o_orderkey) AS orders_count,
    SUM(ro.o_totalprice) AS total_sales,
    SUM(ro.l_extendedprice * (1 - ro.l_discount)) AS total_revenue,
    AVG(ro.o_totalprice) AS average_order_value
FROM 
    TopSuppliers tos
JOIN 
    RecentOrders ro ON tos.s_suppkey = ro.l_suppkey
GROUP BY 
    tos.nation, tos.s_name
ORDER BY 
    total_sales DESC;
