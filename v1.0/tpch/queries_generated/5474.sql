WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
CustomerSegment AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT o.o_custkey) AS total_customers
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    r.r_name,
    SUM(rr.total_revenue) AS region_revenue,
    cs.total_customers,
    SUM(sr.total_supply_cost) AS region_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedOrders rr ON rr.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    SupplierRevenue sr ON sr.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = n.n_nationkey)
LEFT JOIN 
    CustomerSegment cs ON cs.c_mktsegment IN (SELECT c.c_mktsegment FROM customer c WHERE c.c_nationkey = n.n_nationkey)
GROUP BY 
    r.r_name, cs.total_customers
ORDER BY 
    region_revenue DESC, total_customers DESC;
