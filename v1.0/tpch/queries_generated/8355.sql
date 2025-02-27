WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
PopularSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
RegionNationInfo AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderstatus,
    rn.r_name,
    rn.n_name,
    ps.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    PopularSuppliers ps ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = ps.ps_suppkey)
JOIN 
    RegionNationInfo rn ON rn.n_nationkey IN (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ro.o_orderkey)
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_totalprice DESC, rn.r_name, ps.total_supply_cost DESC;
