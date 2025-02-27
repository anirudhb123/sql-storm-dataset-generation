WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_nationkey
),
RegionDetails AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ss.total_cost) AS region_total_cost,
        SUM(ss.supplier_count) AS total_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    ro.o_orderstatus, 
    rd.r_name AS region_name, 
    rd.region_total_cost,
    rd.total_suppliers
FROM 
    RankedOrders ro
JOIN 
    RegionDetails rd ON ro.o_orderkey % COUNT(DISTINCT ro.o_orderkey) OVER () = (rd.total_suppliers % COUNT(DISTINCT rd.region_total_cost) OVER ())
WHERE 
    ro.order_rank <= 5
ORDER BY 
    rd.region_total_cost DESC, 
    ro.o_totalprice DESC;
