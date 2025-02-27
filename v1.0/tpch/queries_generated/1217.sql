WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    cos.total_orders,
    cos.total_spent,
    ls.net_revenue AS order_revenue,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY ls.net_revenue DESC) AS rank
FROM 
    customer_order_summary cos
JOIN 
    customer cs ON cos.c_custkey = cs.c_custkey
LEFT JOIN 
    supplier_summary ss ON ss.total_parts > 0
LEFT JOIN 
    lineitem_summary ls ON cos.total_orders > 0
WHERE 
    ss.total_supply_cost IS NOT NULL 
    AND (cs.c_acctbal IS NULL OR cs.c_acctbal > 100)
ORDER BY 
    cs.c_name, ss.total_supply_cost DESC;

