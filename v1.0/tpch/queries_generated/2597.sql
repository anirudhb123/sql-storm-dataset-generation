WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    o.o_orderkey,
    r.c_name,
    r.o_totalprice,
    COALESCE(sp.total_avail_qty, 0) AS total_available_quantity,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    nd.n_name AS nation_name,
    nd.region_name
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey
JOIN 
    NationDetails nd ON r.c_nationkey = nd.n_nationkey
WHERE 
    (sp.total_avail_qty IS NULL OR sp.total_supply_cost < 100.00) 
    AND r.rn <= 5
ORDER BY 
    r.o_totalprice DESC, r.o_orderkey;
