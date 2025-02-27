WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o2.o_orderkey,
        o2.o_custkey,
        o2.o_totalprice,
        o2.o_orderdate,
        oh.level + 1
    FROM 
        orders o2
    JOIN 
        order_hierarchy oh ON o2.o_custkey = oh.o_custkey
    WHERE 
        o2.o_orderdate > oh.o_orderdate
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
supplier_part_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_name,
    cs.total_spent,
    cs.order_count,
    cs.average_order_value,
    sp.s_suppkey,
    sp.total_value,
    sp.part_count,
    DENSE_RANK() OVER (PARTITION BY cs.order_count ORDER BY cs.total_spent DESC) AS spending_rank,
    COALESCE(sp.part_count, 0) AS null_part_count_logic
FROM 
    customer_summary cs
LEFT JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    supplier_part_summary sp ON sp.total_value > (SELECT AVG(total_value) FROM supplier_part_summary)
WHERE 
    cs.average_order_value > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    spending_rank, c.c_name;
