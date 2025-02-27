WITH RECURSIVE OrderStats AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(ol.l_extendedprice * (1 - ol.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
        LEFT JOIN lineitem ol ON o.o_orderkey = ol.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01'
    GROUP BY 
        o.o_custkey
), SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), RegionNation AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        r.r_name AS region_name,
        n.n_name AS nation_name
    FROM 
        region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    o.c_custkey,
    c.c_name,
    rs.region_name,
    ns.nation_name,
    os.total_orders,
    os.total_revenue,
    COALESCE(p.p_brand, 'Unknown') AS product_brand,
    COALESCE(ss.supplier_count, 0) AS supplier_count,
    (CASE 
        WHEN os.total_revenue IS NOT NULL THEN ROUND(os.total_revenue / NULLIF(os.total_orders, 0), 2)
        ELSE 0 
     END) AS avg_revenue_per_order
FROM 
    customer c
    LEFT JOIN OrderStats os ON c.c_custkey = os.o_custkey
    LEFT JOIN lineitem l ON c.c_custkey = l.l_orderkey
    LEFT JOIN part p ON l.l_partkey = p.p_partkey
    LEFT JOIN SupplierPartStats ss ON p.p_partkey = ss.ps_partkey
    LEFT JOIN RegionNation rs ON c.c_nationkey = rs.n_nationkey 
WHERE 
    os.revenue_rank <= 5 OR os.total_orders IS NULL
ORDER BY 
    avg_revenue_per_order DESC, 
    c.c_name ASC 
LIMIT 10;
