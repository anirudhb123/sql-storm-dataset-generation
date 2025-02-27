WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' 
        AND o.o_orderdate < DATE '2022-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(ro.total_revenue) AS total_revenue,
    SUM(sr.total_supply_cost) AS total_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
JOIN 
    SupplierRevenue sr ON sr.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
    )
WHERE 
    o.o_orderstatus = 'F'
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_revenue DESC, order_count DESC;
