WITH RECURSIVE regional_supply AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey, n.n_name, r.r_name
),
aggregated_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS net_order_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_sequence
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
),
supplier_sales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate > DATEADD(month, -6, CURRENT_DATE)
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.region_name,
    r.nation_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count,
    r.total_available_quantity,
    CASE 
        WHEN r.total_available_quantity > COALESCE(ss.total_sales, 0) THEN 'Surplus'
        WHEN r.total_available_quantity < COALESCE(ss.total_sales, 0) THEN 'Deficit'
        ELSE 'Balanced'
    END AS supply_status,
    AVG(a.net_order_value) AS avg_order_value
FROM 
    regional_supply r
LEFT JOIN 
    supplier_sales ss ON r.r_regionkey = ss.s_suppkey 
LEFT JOIN 
    aggregated_orders a ON ss.order_count > 0
GROUP BY 
    r.region_name, r.nation_name, r.total_available_quantity
ORDER BY 
    avg_order_value DESC NULLS LAST,
    supply_status ASC,
    r.region_name;
