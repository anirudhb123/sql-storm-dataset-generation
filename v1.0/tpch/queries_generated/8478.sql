WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), detailed_lineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    JOIN 
        ranked_orders r ON l.l_orderkey = r.o_orderkey
    WHERE 
        r.order_rank <= 10
    GROUP BY 
        l.l_orderkey
), supplier_part_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name AS region,
    SUM(dl.total_revenue) AS region_revenue,
    COUNT(DISTINCT dl.l_orderkey) AS total_orders,
    SUM(sp.total_available_qty) AS total_available_parts,
    AVG(sp.avg_supply_cost) AS avg_supply_cost_per_part
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    ranked_orders o ON c.c_custkey = o.o_custkey
JOIN 
    detailed_lineitems dl ON o.o_orderkey = dl.l_orderkey
JOIN 
    supplier_part_summary sp ON sp.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
GROUP BY 
    r.r_name
ORDER BY 
    region_revenue DESC
LIMIT 10;
