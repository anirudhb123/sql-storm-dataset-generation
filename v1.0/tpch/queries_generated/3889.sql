WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
FilteredLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_linenumber) AS line_count
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        li.l_orderkey
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(SUM(rlo.total_revenue), 0) AS revenue,
    SUM(ss.total_available) AS total_available_parts,
    AVG(ss.avg_supply_cost) AS average_supply_cost,
    AVG(ro.o_totalprice) AS avg_order_price
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT li.l_orderkey FROM lineitem li WHERE li.l_returnflag = 'R')
LEFT JOIN 
    FilteredLineItems rlo ON rlo.l_orderkey = ro.o_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = n.n_nationkey)
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(rlo.total_revenue) > 0 OR AVG(ro.o_totalprice) > 100
ORDER BY 
    revenue DESC, average_supply_cost ASC;
