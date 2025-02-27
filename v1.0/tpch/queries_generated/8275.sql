WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
SupplyStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue
    FROM 
        lineitem ls
    JOIN 
        supplier s ON ls.l_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_revenue > (
            SELECT AVG(total_revenue) 
            FROM (
                SELECT 
                    SUM(ls_sub.l_extendedprice * (1 - ls_sub.l_discount)) AS total_revenue
                FROM 
                    lineitem ls_sub
                GROUP BY 
                    ls_sub.l_suppkey
            ) AS RevenueSubquery
        )
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    SUM(ps.total_available_qty) AS total_parts_available,
    SUM(ts.total_revenue) AS total_supplier_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplyStats ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC, avg_order_value DESC;
