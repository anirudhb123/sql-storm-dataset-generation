WITH recent_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
), 
supplier_stats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost 
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
), 
summary_stats AS (
    SELECT 
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value,
        SUM(ss.total_avail_qty) AS total_supply_available,
        AVG(ss.avg_supply_cost) AS avg_supply_cost_per_supplier
    FROM 
        recent_orders o
    JOIN 
        customer c ON o.c_nationkey = c.c_nationkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON c.c_custkey = ps.ps_suppkey
    JOIN 
        supplier_stats ss ON ps.ps_suppkey = ss.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    s.*, 
    COUNT(DISTINCT p.p_partkey) AS unique_parts_count,
    AVG(p.p_retailprice) AS avg_part_price
FROM 
    summary_stats s
JOIN 
    partsupp p ON p.ps_suppkey IN (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_availqty > 0
    )
GROUP BY 
    s.region_name, s.n_name, s.order_count, s.total_revenue, s.avg_order_value, s.total_supply_available, s.avg_supply_cost_per_supplier
ORDER BY 
    total_revenue DESC
LIMIT 10;
