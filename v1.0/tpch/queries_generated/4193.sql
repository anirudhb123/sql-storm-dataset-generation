WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
NationalStatistics AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        nations n 
    LEFT JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON o.o_custkey = c.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ns.order_count,
    ns.average_order_value,
    SUM(si.total_supply_value) AS total_supply_value,
    COUNT(DISTINCT ro.o_orderkey) AS ranked_order_count
FROM 
    region r
LEFT JOIN 
    nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    NationalStatistics n_stats ON n_stats.n_nationkey = ns.n_nationkey
LEFT JOIN 
    SupplierInfo si ON si.s_nationkey = ns.n_nationkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderstatus = 'F'  -- Assuming 'F' for finished orders
GROUP BY 
    r.r_name, ns.n_name, ns.order_count, ns.average_order_value
HAVING 
    AVG(ns.average_order_value) > 500.00 OR COUNT(si.s_suppkey) > 5
ORDER BY 
    total_supply_value DESC, region_name, nation_name;
