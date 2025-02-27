WITH region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
), 
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
orders_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O') AND 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
ranked_orders AS (
    SELECT 
        o.*,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY total_revenue DESC) AS order_rank
    FROM 
        orders_summary o
)
SELECT 
    r.r_name,
    s.s_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(o.total_revenue) AS total_revenue,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(o.total_revenue) DESC) AS region_rank
FROM 
    region_summary r
JOIN 
    nation n ON r.nation_count > 0
JOIN 
    supplier_summary s ON s.total_supply_value > 10000
LEFT JOIN 
    ranked_orders o ON o.o_orderstatus = 'F'
GROUP BY 
    r.r_regionkey, r.r_name, s.s_name
HAVING 
    SUM(o.total_revenue) > 0 AND 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    region_rank, total_revenue DESC;
