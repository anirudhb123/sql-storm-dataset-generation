WITH supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
nation_details AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        r.r_comment
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    ns.n_name,
    ns.region_name,
    sd.s_name,
    cs.c_name,
    cs.total_orders,
    cs.order_count,
    ls.net_revenue,
    ls.line_count,
    sd.total_supply_cost,
    CASE 
        WHEN sd.total_supply_cost IS NULL THEN 'No Supply Cost'
        ELSE 'Has Supply Cost'
    END AS supply_cost_status
FROM 
    supplier_details sd
JOIN 
    nation_details ns ON sd.s_nationkey = ns.n_nationkey
LEFT JOIN 
    customer_order_summary cs ON sd.s_suppkey = cs.c_custkey
LEFT JOIN 
    lineitem_summary ls ON cs.order_count = ls.line_count
WHERE 
    (sd.total_supply_cost > 1000 OR cs.total_orders IS NULL)
ORDER BY 
    ns.region_name, 
    sd.total_supply_cost DESC, 
    cs.order_count DESC;
