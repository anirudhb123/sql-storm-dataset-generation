WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
formatted_region AS (
    SELECT 
        r.r_regionkey,
        CONCAT('Region: ', r.r_name, ' - ', LEFT(r.r_comment, 50)) AS formatted_comment
    FROM 
        region r
),
customer_segmentation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
    HAVING 
        COUNT(o.o_orderkey) > 5
),
supplier_parts AS (
    SELECT 
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        STRING_AGG(CONCAT('Part Key: ', ps.ps_partkey), '; ') AS part_keys
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 2
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sf.s_name,
    cs.c_name,
    cs.total_orders,
    fr.formatted_comment
FROM 
    ranked_parts rp
JOIN 
    supplier_parts sf ON sf.part_count > 3
JOIN 
    customer_segmentation cs ON cs.total_orders > 5
JOIN 
    formatted_region fr ON fr.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey))
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC
LIMIT 10;
