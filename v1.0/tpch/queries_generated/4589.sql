WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_name, 
        c.c_nationkey
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost, 
        (ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(COALESCE(sp.total_supply_cost, 0)) AS total_supply_cost,
    ROUND(AVG(ro.total_revenue), 2) AS avg_revenue_per_order
FROM 
    ranked_orders ro
JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierPartInfo sp ON sp.p_partkey IN (
        SELECT p_partkey
        FROM part
        WHERE p_size = 15
    ) 
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_revenue_per_order DESC;
