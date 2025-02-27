
WITH RECURSIVE part_hierarchy AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_retailprice,
        1 AS level
    FROM 
        part 
    WHERE 
        p_size > 10
    UNION ALL
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice * 0.9 AS discounted_price,
        ph.level + 1
    FROM 
        part_hierarchy ph
    JOIN 
        partsupp ps ON ph.p_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size <= 10
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        RANK() OVER (ORDER BY COALESCE(SUM(o.o_totalprice), 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_average_cost AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
checkout_summary AS (
    SELECT 
        ch.customer_id,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS total_revenue
    FROM 
        (SELECT 
            c.c_custkey AS customer_id
        FROM 
            customer c
        WHERE 
            c.c_mktsegment = 'BUILDING') ch
    LEFT JOIN 
        orders o ON ch.customer_id = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        ch.customer_id
)
SELECT 
    p.p_name,
    ph.level,
    cs.c_name,
    cs.total_spent,
    sac.avg_supply_cost,
    COALESCE(co.order_count, 0) AS total_orders,
    COALESCE(co.total_revenue, 0) AS total_revenue
FROM 
    part_hierarchy ph
JOIN 
    part p ON ph.p_partkey = p.p_partkey
JOIN 
    customer_summary cs ON cs.rank <= 10
JOIN 
    supplier_average_cost sac ON sac.avg_supply_cost < 100
LEFT JOIN 
    checkout_summary co ON cs.c_custkey = co.customer_id
WHERE 
    ph.p_retailprice > 50
    AND (ph.level > 1 OR ph.p_name LIKE '%widget%')
ORDER BY 
    ph.level, cs.total_spent DESC;
