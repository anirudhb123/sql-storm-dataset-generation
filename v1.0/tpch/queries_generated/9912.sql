WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
NationSuppliers AS (
    SELECT 
        n.n_name,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, s.s_name
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    ns.s_name AS supplier,
    ro.o_orderkey AS top_order_id,
    ro.o_orderdate AS order_date,
    ro.o_totalprice AS order_total,
    ns.total_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationSuppliers ns ON n.n_nationkey = ns.n_nationkey
JOIN 
    RankedOrders ro ON n.n_nationkey = ro.c_nationkey
WHERE 
    ro.rn = 1
ORDER BY 
    r.r_name, ns.total_supply_cost DESC
LIMIT 10;
