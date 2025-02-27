WITH RECURSIVE customer_orders AS (
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
    
    UNION ALL 
    
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders + 1,
        co.total_spent + COALESCE(SUM(o.o_totalprice), 0)
    FROM 
        customer_orders co
    LEFT JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderkey IS NOT NULL
    GROUP BY 
        co.c_custkey, co.c_name, co.total_orders, co.total_spent
),
ranked_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(co.total_orders, 0) AS total_orders,
        COALESCE(co.total_spent, 0) AS total_spent,
        RANK() OVER (ORDER BY COALESCE(co.total_spent, 0) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_orders co ON c.c_custkey = co.c_custkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity 
            ELSE 0 
        END) AS total_returned,
    (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS num_suppliers,
    rg.r_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region rg ON n.n_regionkey = rg.r_regionkey
LEFT JOIN 
    ranked_orders ro ON ro.c_custkey = s.s_nationkey
WHERE 
    p.p_size > 10 AND 
    (p.p_retailprice IS NOT NULL AND p.p_retailprice < 500)
GROUP BY 
    p.p_partkey, p.p_name, rg.r_name
HAVING 
    total_quantity > 100 
ORDER BY 
    total_quantity DESC;
