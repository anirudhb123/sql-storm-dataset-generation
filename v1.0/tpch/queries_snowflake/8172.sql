
WITH Revenue AS (
    SELECT 
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        c.c_mktsegment
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationRevenue AS (
    SELECT 
        n.n_name,
        r.c_mktsegment AS region_name,
        SUM(r.total_revenue) AS total_revenue
    FROM 
        Revenue r
    JOIN 
        customer c ON r.c_mktsegment = c.c_mktsegment
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name, r.c_mktsegment
)
SELECT 
    n.n_name,
    n.region_name,
    n.total_revenue,
    s.s_name,
    s.total_supply_cost
FROM 
    NationRevenue n
JOIN 
    SupplierInfo s ON n.n_name = (SELECT n2.n_name FROM nation n2 WHERE n2.n_nationkey = s.s_nationkey)
ORDER BY 
    n.total_revenue DESC, s.total_supply_cost ASC
LIMIT 10;
