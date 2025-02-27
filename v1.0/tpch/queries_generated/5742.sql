WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, p.p_name, s.s_name
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    ro.o_totalprice,
    SUM(lia.revenue) AS total_revenue,
    SUM(sd.total_supply_cost) AS total_supply_cost,
    MAX(ro.order_rank) AS max_order_rank
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemAnalysis lia ON ro.o_orderkey = lia.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON sd.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
WHERE 
    ro.order_rank <= 10
GROUP BY 
    ro.o_orderkey, ro.o_orderdate, ro.c_name, ro.o_totalprice
ORDER BY 
    ro.o_orderdate, ro.c_name;
