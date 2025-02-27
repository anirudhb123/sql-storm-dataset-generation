WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND p.p_size > 10
),
supplier_filter AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        MAX(ps.ps_supplycost) as max_supplycost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 500.00
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) as total_orders,
        SUM(o.o_totalprice) as total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
),
avg_orders AS (
    SELECT 
        AVG(total_orders) as avg_orders, 
        AVG(total_spent) as avg_spent
    FROM 
        customer_orders
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    sf.s_name,
    sf.max_supplycost,
    co.c_name,
    co.total_orders,
    co.total_spent,
    ao.avg_orders,
    CASE 
        WHEN co.total_spent > ao.avg_spent THEN 'Above Average'
        WHEN co.total_spent < ao.avg_spent THEN 'Below Average'
        ELSE 'Average Spender'
    END as spending_category
FROM 
    ranked_parts rp
INNER JOIN 
    supplier_filter sf ON sf.max_supplycost < rp.p_retailprice
JOIN 
    customer_orders co ON co.total_orders > 1
CROSS JOIN 
    avg_orders ao
WHERE 
    rp.rn = 1
    AND sf.s_acctbal IS NOT NULL
    AND sf.s_name IS NOT NULL
    AND co.c_name IS NOT NULL
ORDER BY 
    rp.p_retailprice DESC, 
    co.total_spent DESC
LIMIT 100;
