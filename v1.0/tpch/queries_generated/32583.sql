WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        1 AS level,
        NULL::integer AS parent_key
    FROM 
        supplier s
    WHERE 
        s.s_comment LIKE '%important%'
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        sh.level + 1,
        sh.s_suppkey AS parent_key
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
)

, customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

, total_supplier_cost AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)

SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(so.total_order_count, 0) AS total_orders,
    COALESCE(tc.total_cost, 0) AS total_cost,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COALESCE(tc.total_cost, 0) DESC) AS cost_rank,
    sh.level AS hierarchy_level
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN (
    SELECT
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
) so ON n.n_nationkey = so.c_nationkey
LEFT JOIN total_supplier_cost tc ON n.n_nationkey = tc.p_partkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_suppkey
WHERE 
    r.r_name LIKE '%North%'
AND 
    (total_cost > 1000 OR total_orders > 10)
ORDER BY 
    nation_name, region_name;
