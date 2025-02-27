WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_mktsegment,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    WHERE 
        ro.o_totalprice > 5000
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_mktsegment
)
SELECT 
    n.n_name,
    r.r_name,
    MAX(hv.total_quantity) AS max_order_quantity,
    SUM(spd.total_available) AS sum_available_parts,
    SUM(spd.avg_supply_cost * spd.total_available) AS total_supply_cost
FROM 
    HighValueOrders hv
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = hv.o_orderkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = hv.o_orderkey)
JOIN 
    SupplierPartDetails spd ON ps.ps_partkey = spd.ps_partkey
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT hv.o_orderkey) > 10
ORDER BY 
    max_order_quantity DESC, r.r_name ASC;
