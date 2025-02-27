WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_nationkey, 
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT ro.o_orderkey) AS total_orders, 
    SUM(lia.revenue) AS total_revenue, 
    AVG(spd.ps_supplycost) AS avg_supply_cost
FROM 
    RankedOrders ro
JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    LineItemAggregates lia ON ro.o_orderkey = lia.l_orderkey
LEFT JOIN 
    SupplierPartDetails spd ON spd.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
WHERE 
    ro.order_rank <= 10 
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC, total_revenue DESC;
