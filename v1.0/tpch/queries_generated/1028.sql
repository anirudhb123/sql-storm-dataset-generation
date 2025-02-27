WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
),
SupplierRegions AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    ro.o_orderkey,
    ro.total_revenue,
    sr.region_name,
    sr.supplier_count,
    COALESCE(ts.total_supply_cost, 0) AS supplier_total_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierRegions sr ON sr.supplier_count > 0
LEFT JOIN 
    TopSuppliers ts ON ts.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey) LIMIT 1)
WHERE 
    ro.revenue_rank = 1
ORDER BY 
    ro.total_revenue DESC, sr.region_name;
