
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 500
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    COALESCE(sp.total_avail_qty, 0) AS available_quantity,
    COALESCE(sp.avg_supply_cost, 0) AS average_supply_cost,
    hp.p_name,
    hp.p_retailprice
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierStats sp ON sp.ps_partkey IN (SELECT li.l_partkey FROM lineitem li WHERE li.l_orderkey = ro.o_orderkey)
LEFT JOIN 
    HighValueParts hp ON hp.p_partkey = sp.ps_partkey
WHERE 
    ro.rn <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;
