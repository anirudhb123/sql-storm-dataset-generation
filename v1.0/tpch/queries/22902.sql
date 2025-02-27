WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
), 
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        l.l_orderkey
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
CustomerSegments AS (
    SELECT 
        c.c_nationkey, 
        c.c_mktsegment,
        COUNT(*) AS customers_count
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey, 
        c.c_mktsegment
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(AVG(hv.total_revenue), 0) AS avg_total_revenue,
    SUM(CASE WHEN so.o_orderkey IS NOT NULL THEN 1 ELSE 0 END) AS successful_orders,
    COUNT(DISTINCT ss.s_suppkey) AS unique_suppliers,
    STRING_AGG(DISTINCT cs.c_mktsegment, ', ') AS market_segments
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerSegments cs ON n.n_nationkey = cs.c_nationkey
JOIN 
    (SELECT DISTINCT o.o_orderkey FROM RankedOrders o WHERE o.order_rank <= 5) so ON TRUE
LEFT JOIN 
    HighValueLineItems hv ON so.o_orderkey = hv.l_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.supplied_parts > 0
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT cs.c_mktsegment) > 1 
    AND SUM(ss.total_supply_cost) IS NOT NULL
ORDER BY 
    avg_total_revenue DESC;