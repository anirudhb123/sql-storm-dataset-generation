WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'P') AND 
        o.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
),
Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
HighValueSuppliers AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
EligibleCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus NOT IN ('F', 'X')
    GROUP BY 
        c.c_custkey, c.c_mktsegment
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 3
)

SELECT 
    DISTINCT c.c_name,
    nc.n_name,
    r.region_name,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns,
    COALESCE(SUM(CASE WHEN l.l_shipmode = 'AIR' THEN l.l_extendedprice END), 0) AS air_ship_revenue
FROM 
    lineitem l
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    EligibleCustomers ec ON ec.c_custkey = ro.o_custkey
JOIN 
    Nations nc ON s.s_nationkey = nc.n_nationkey
JOIN 
    region r ON nc.region_name = r.r_name
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL) AND
    l.l_quantity IS NOT NULL
GROUP BY 
    c.c_name, nc.n_name, r.region_name, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL AND
    SUM(CASE WHEN l.l_returnflag IN ('R', 'A') THEN 1 ELSE 0 END) > 0
ORDER BY 
    total_revenue DESC NULLS LAST;
