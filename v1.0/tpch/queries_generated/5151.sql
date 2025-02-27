WITH regional_supplier_stats AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, n.n_name
), order_stats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    rss.region_name,
    rss.nation_name,
    rss.supplier_count,
    rss.total_available_quantity,
    rss.total_supply_cost,
    os.order_count,
    os.total_order_value,
    os.avg_order_value
FROM 
    regional_supplier_stats rss
LEFT JOIN 
    order_stats os ON rss.nation_name = (SELECT n_name FROM nation WHERE n_nationkey = os.c_nationkey)
ORDER BY 
    rss.region_name, rss.nation_name;
