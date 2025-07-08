WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_nationkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000.00
),
FinalReport AS (
    SELECT 
        r.r_name AS region,
        COUNT(DISTINCT ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_revenue,
        AVG(fs.total_supply_cost) AS avg_supply_cost_per_supplier
    FROM 
        RankedOrders ro
    JOIN 
        region r ON EXISTS (
            SELECT 1 
            FROM nation n 
            WHERE n.n_nationkey = ro.c_nationkey AND n.n_regionkey = r.r_regionkey
        )
    JOIN 
        FilteredSuppliers fs ON fs.n_nationkey = ro.c_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    fr.region,
    fr.total_orders,
    fr.total_revenue,
    fr.avg_supply_cost_per_supplier
FROM 
    FinalReport fr
ORDER BY 
    fr.total_revenue DESC
LIMIT 10;