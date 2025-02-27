WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
top_segments AS (
    SELECT 
        mkt_segment, 
        COUNT(orderkey) AS order_count, 
        AVG(o_totalprice) AS avg_order_value
    FROM 
        ranked_orders
    WHERE 
        order_rank <= 5
    GROUP BY 
        c_mktsegment
),
supplier_costs AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        p.p_type
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_type
)
SELECT 
    ns.n_name,
    r.r_name,
    ts.order_count,
    ts.avg_order_value,
    AVG(sc.total_supply_cost) AS avg_supply_cost_per_type
FROM 
    nation ns
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
JOIN 
    customer c ON ns.n_nationkey = c.c_nationkey
JOIN 
    top_segments ts ON c.c_mktsegment = ts.mkt_segment
JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
JOIN 
    supplier_costs sc ON s.s_suppkey = sc.p_partkey
GROUP BY 
    ns.n_name, r.r_name, ts.order_count, ts.avg_order_value
ORDER BY 
    ts.order_count DESC, avg_supply_cost_per_type DESC;
