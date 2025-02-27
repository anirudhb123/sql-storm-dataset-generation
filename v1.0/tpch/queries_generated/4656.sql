WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND 
        l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        r.r_name AS region_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal, r.r_name
),
detailed_summary AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.region_name,
        cs.order_count,
        os.total_order_value,
        os.item_count,
        ss.total_avail_qty,
        ss.total_supply_cost
    FROM 
        customer_summary cs
    LEFT JOIN 
        order_summary os ON cs.c_custkey = os.o_custkey
    LEFT JOIN 
        supplier_summary ss ON ss.total_avail_qty IS NOT NULL
)
SELECT 
    ds.c_custkey,
    ds.c_name,
    ds.region_name,
    ds.order_count,
    COALESCE(ds.total_order_value, 0) AS total_order_value,
    COALESCE(ds.item_count, 0) AS item_count,
    COALESCE(ds.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ds.total_supply_cost, 0) AS total_supply_cost
FROM 
    detailed_summary ds
WHERE 
    (ds.order_count > 0 OR ds.order_count IS NULL)
ORDER BY 
    total_order_value DESC, item_count DESC;
