WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
SupplierRegionComments AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        COUNT(s.s_suppkey) AS supplier_count,
        STRING_AGG(s.s_comment, '; ') WITHIN GROUP (ORDER BY s.s_suppkey) AS supply_comments
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    o.o_orderkey, 
    o.o_custkey,
    COALESCE(SUM(f.net_sales), 0) AS total_net_sales,
    COALESCE(SUM(r.total_supply_cost), 0) AS total_supply_cost,
    sr.nation_name,
    sr.region_name,
    sr.supplier_count,
    sr.supply_comments
FROM 
    FilteredOrders f
FULL OUTER JOIN 
    RankedSuppliers r ON f.o_custkey = r.s_nationkey
JOIN 
    SupplierRegionComments sr ON r.s_nationkey = sr.nation_name
GROUP BY 
    o.o_orderkey, o.o_custkey, sr.nation_name, sr.region_name, sr.supplier_count, sr.supply_comments
HAVING 
    (SUM(f.net_sales) > 1000 OR SUM(r.total_supply_cost) < 500) AND 
    COUNT(DISTINCT r.s_suppkey) > 0
ORDER BY 
    total_net_sales DESC NULLS LAST, 
    total_supply_cost ASC NULLS FIRST;
