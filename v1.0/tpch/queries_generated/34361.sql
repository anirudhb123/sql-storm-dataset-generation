WITH RECURSIVE recursive_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_depth
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ro.order_depth + 1
    FROM 
        orders o
    JOIN 
        recursive_orders ro ON o.o_custkey = ro.o_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01'
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_part_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    cos.total_spent,
    spd.p_name,
    spd.total_available_qty,
    spd.avg_supply_cost,
    ROUND(cos.total_spent / NULLIF(spd.avg_supply_cost, 0), 2) AS cost_to_spending_ratio
FROM 
    customer_order_summary cos
JOIN 
    supplier_part_details spd ON cos.order_count > 5
WHERE 
    cos.spending_rank <= 10
ORDER BY 
    cost_to_spending_ratio DESC
LIMIT 30;
