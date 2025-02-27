WITH categorized_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice < 50 THEN 'Low'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS price_category,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment
    FROM 
        part p
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey,
        s.s_name,
        r.r_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey,
        c.c_name
)
SELECT 
    cp.p_name,
    cp.price_category,
    s.s_name,
    s.region_name,
    co.c_name,
    co.order_count,
    co.total_spent,
    cp.short_comment
FROM 
    categorized_parts cp
JOIN 
    supplier_info s ON cp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN 
    customer_orders co ON co.total_spent > 1000
WHERE 
    cp.price_category = 'High'
ORDER BY 
    co.total_spent DESC, 
    cp.price_category, 
    s.region_name, 
    co.c_name;
