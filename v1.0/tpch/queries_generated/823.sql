WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
SupplyNationStats AS (
    SELECT 
        n.n_name,
        SUM(total_supplycost) AS total_nation_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    WHERE 
        rs.rank = 1
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    COALESCE(rns.total_nation_supplycost, 0) AS best_supplier_cost,
    COUNT(ro.o_orderkey) AS recent_orders_count,
    SUM(ro.order_total) AS recent_orders_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplyNationStats rns ON n.n_name = rns.n_name
LEFT JOIN 
    RecentOrders ro ON n.n_nationkey = ro.o_custkey
GROUP BY 
    r.r_name, rns.total_nation_supplycost
ORDER BY 
    best_supplier_cost DESC, recent_orders_value DESC;
