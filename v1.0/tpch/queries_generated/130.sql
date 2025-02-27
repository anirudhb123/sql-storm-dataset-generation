WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) > 1
)
SELECT 
    ro.o_orderkey,
    ro.o_custkey,
    ro.o_orderdate,
    ro.total_revenue,
    ss.total_available,
    ss.average_supply_cost,
    tr.r_name AS region_name,
    (CASE 
        WHEN ro.total_revenue > 10000 THEN 'High' 
        WHEN ro.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium' 
        ELSE 'Low' 
    END) AS revenue_category
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierStats ss ON ss.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE 'Widget%')
INNER JOIN 
    TopRegions tr ON ro.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ANY (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = tr.r_regionkey))
WHERE 
    ro.order_rank = 1
ORDER BY 
    ro.total_revenue DESC, tr.nation_count ASC;
