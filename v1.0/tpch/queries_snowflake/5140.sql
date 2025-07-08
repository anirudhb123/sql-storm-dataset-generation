
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
),
TopOrders AS (
    SELECT 
        r.r_regionkey,
        n.n_name,
        SUM(ro.o_totalprice) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rn <= 10
    GROUP BY 
        r.r_regionkey, n.n_name
),
SupplierRevenue AS (
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND 
        l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        ps.ps_suppkey, s.s_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    tr.total_revenue,
    sr.s_name,
    sr.total_cost
FROM 
    RankedOrders ro
JOIN 
    TopOrders tr ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate = ro.o_orderdate)
JOIN 
    SupplierRevenue sr ON sr.total_cost = (
        SELECT MAX(l.l_discount * l.l_extendedprice) 
        FROM lineitem l 
        WHERE l.l_orderkey = ro.o_orderkey
    )
ORDER BY 
    ro.o_orderdate DESC,
    ro.o_totalprice ASC;
