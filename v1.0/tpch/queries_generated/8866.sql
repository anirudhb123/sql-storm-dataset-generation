WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_mktsegment
    FROM 
        RankedOrders ro
    WHERE 
        ro.price_rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
),
AggregatedData AS (
    SELECT 
        to.c_mktsegment,
        SUM(to.o_totalprice) AS total_sales,
        COUNT(DISTINCT to.o_orderkey) AS total_orders,
        AVG(sd.ps_supplycost) AS avg_supply_cost
    FROM 
        TopOrders to
    JOIN 
        SupplierDetails sd ON (sd.ps_availqty > 100)
    GROUP BY 
        to.c_mktsegment
)
SELECT 
    ad.c_mktsegment,
    ad.total_sales,
    ad.total_orders,
    ad.avg_supply_cost,
    r.r_name
FROM 
    AggregatedData ad
JOIN 
    nation n ON n.n_nationkey = (SELECT MIN(s_nationkey) FROM supplier WHERE s_suppkey = sd.s_suppkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    ad.total_sales DESC;
