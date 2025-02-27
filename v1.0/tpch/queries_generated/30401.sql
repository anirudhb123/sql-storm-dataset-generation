WITH RECURSIVE TotalSalesCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    UNION ALL
    SELECT 
        ts.c_custkey, 
        ts.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) 
    FROM 
        TotalSalesCTE ts
    JOIN 
        lineitem l ON ts.c_custkey = l.l_orderkey
    GROUP BY 
        ts.c_custkey, ts.c_name
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS supplier_nation,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name, r.r_name
),
SalesRank AS (
    SELECT 
        c.c_name,
        ts.total_sales,
        DENSE_RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSalesCTE ts
    JOIN 
        customer c ON ts.c_custkey = c.c_custkey
)
SELECT 
    sr.region_name,
    sr.supplier_nation,
    SUM(sr.total_supply_cost) AS total_supply_in_region,
    COALESCE(SR.total_supply_cost, 0) AS cost_with_null_handling,
    COUNT(DISTINCT r_regionkey) AS distinct_regions,
    COUNT(DISTINCT o_orderkey) FILTER (WHERE o_orderstatus = 'O') AS completed_orders,
    STRING_AGG(DISTINCT c_name, ', ' ORDER BY c_name) AS customer_names
FROM 
    SupplierRegion sr
LEFT JOIN 
    lineitem l ON sr.s_suppkey = l.l_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    nation n ON sr.supplier_nation = n.n_name
CROSS JOIN 
    region r
GROUP BY 
    sr.region_name, sr.supplier_nation
HAVING 
    COUNT(o_orderkey) > 10 
    AND SUM(l.l_quantity) > 100
ORDER BY 
    total_supply_in_region DESC;
