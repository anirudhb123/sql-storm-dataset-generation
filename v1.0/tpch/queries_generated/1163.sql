WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER(PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND o.o_totalprice > 1000
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        s.s_name AS supplier_name,
        s.s_nationkey
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    COUNT(ro.o_orderkey) AS order_count,
    SUM(ro.o_totalprice) AS total_revenue,
    MAX(ro.o_orderdate) AS last_order_date,
    AVG(ns.total_supply_value) AS avg_supply_value,
    STRING_AGG(DISTINCT sp.p_name, ', ') AS product_names
FROM 
    RankedOrders ro
JOIN 
    customer c ON ro.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierParts sp ON ro.o_orderkey = sp.p_partkey
JOIN 
    NationSummary ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    ro.OrderRank = 1
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    COUNT(ro.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, region_name;
