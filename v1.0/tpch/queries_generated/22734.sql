WITH RECURSIVE recursive_part AS (
    SELECT 
        p_partkey,
        p_name,
        p_retailprice,
        p_size,
        p_comment,
        LEAD(p_retailprice) OVER (ORDER BY p_partkey) AS next_price
    FROM 
        part
    WHERE 
        p_size > 10
    UNION ALL
    SELECT 
        p_partkey,
        p_name,
        p_retailprice * 1.1 AS p_retailprice,
        p_size,
        p_comment,
        LEAD(p_retailprice) OVER (ORDER BY p_partkey) AS next_price
    FROM 
        recursive_part
    WHERE 
        next_price IS NOT NULL
), 
customer_summary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(l.l_linenumber) AS total_items,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1995-01-01' AND CURRENT_DATE
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    cs.total_spent,
    cs.order_count,
    ss.total_supply_cost,
    ls.total_line_value,
    COALESCE(NULLIF(cs.total_spent / NULLIF(ss.total_supply_cost, 0), 0), 1) AS cost_effectiveness,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY cs.total_spent DESC) AS effectiveness_rank
FROM 
    recursive_part p
LEFT JOIN 
    customer_summary cs ON cs.order_rank = 1
LEFT JOIN 
    supplier_summary ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = p.p_partkey
        ORDER BY ps.ps_supplycost DESC
        LIMIT 1
    )
FULL OUTER JOIN 
    lineitem_summary ls ON ls.l_orderkey = (
        SELECT o.o_orderkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = p.p_partkey
        ORDER BY o.o_totalprice DESC
        LIMIT 1
    )
WHERE 
    p.p_comment LIKE '%excellent%'
ORDER BY 
    effectiveness_rank NULLS LAST;
