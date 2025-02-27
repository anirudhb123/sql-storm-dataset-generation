WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_orders_value,
        COUNT(o.o_orderkey) AS total_orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        SUM(su.total_available_quantity) AS total_parts_available
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier_summary su ON su.s_nationkey = n.n_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name,
    SUM(cs.total_orders_value) AS total_revenue,
    SUM(ss.total_supply_value) AS total_supplier_value,
    SUM(rs.total_parts_available) AS total_parts_available
FROM 
    region_summary r
LEFT JOIN 
    customer_summary cs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = cs.c_nationkey)
LEFT JOIN 
    supplier_summary ss ON r.total_nations > 1
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
