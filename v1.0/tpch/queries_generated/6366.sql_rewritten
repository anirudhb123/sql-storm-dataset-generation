WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.total_supply_cost
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        rnk <= 5
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    ts.s_name,
    ts.s_acctbal,
    ro.total_revenue,
    ro.o_orderkey
FROM 
    TopSuppliers ts
JOIN 
    RecentOrders ro ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey = ro.o_orderkey
    )
ORDER BY 
    ts.total_supply_cost DESC, 
    ro.total_revenue DESC;