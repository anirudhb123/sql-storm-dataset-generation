WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS status_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
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
HighRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.status_rank <= 5
),
NationData AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    d.n_name,
    d.region_name,
    COALESCE(SUM(h.total_revenue), 0) AS total_high_revenue,
    COALESCE(SUM(sr.total_supply_cost), 0) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders
FROM 
    NationData d
LEFT JOIN 
    HighRevenueOrders h ON d.n_nationkey = (SELECT c.c_nationkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderkey IN (SELECT o_orderkey FROM HighRevenueOrders) LIMIT 1)
LEFT JOIN 
    SupplierRevenue sr ON EXISTS (SELECT 1 FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_brand = 'Brand#1')
WHERE 
    d.n_name IS NOT NULL
GROUP BY 
    d.n_name, d.region_name
ORDER BY 
    total_high_revenue DESC,
    total_supply_cost ASC
LIMIT 10;
