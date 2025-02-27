WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
), HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) as total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
), TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) as order_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        order_count DESC
    LIMIT 5
)
SELECT 
    r.r_name,
    h.s_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.o_totalprice) AS total_revenue
FROM 
    TopRegions r
JOIN 
    orders o ON r.n_regionkey = (SELECT n.n_regionkey FROM nation n JOIN customer c ON n.n_nationkey = c.c_nationkey WHERE c.c_custkey = o.o_custkey LIMIT 1)
JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
JOIN 
    HighValueSuppliers h ON ro.o_orderkey = (SELECT ps.ps_partkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey = o.o_orderkey LIMIT 1)
GROUP BY 
    r.r_name, h.s_name
ORDER BY 
    total_revenue DESC;