
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
), 
high_value_lines AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity * l.l_extendedprice * (1 - l.l_discount) AS net_revenue,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Sold'
        END AS sale_status
    FROM 
        lineitem l
    WHERE 
        l.l_tax > 0 AND l.l_discount < 0.10
), 
supplier_data AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(CASE WHEN ps.ps_supplycost < 20.0 THEN ps.ps_availqty ELSE 0 END) AS low_cost_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    r.r_name,
    COALESCE(SUM(hvl.net_revenue), 0) AS total_net_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    sd.supplied_parts,
    MAX(sd.low_cost_avail_qty) AS max_low_cost_qty
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders ro ON c.c_custkey = ro.o_custkey
LEFT JOIN 
    high_value_lines hvl ON ro.o_orderkey = hvl.l_orderkey
LEFT JOIN 
    supplier_data sd ON sd.s_name = (SELECT s_name FROM supplier ORDER BY RANDOM() LIMIT 1)
WHERE 
    r.r_name IS NOT NULL AND 
    (r.r_comment NOT LIKE '%test%' OR r.r_comment IS NULL)
GROUP BY 
    r.r_name, sd.supplied_parts
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 2 OR MAX(sd.supplied_parts) IS NULL
ORDER BY 
    total_net_revenue DESC;
