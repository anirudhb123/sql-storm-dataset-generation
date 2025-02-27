WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS pricing_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
suppliers_with_multiple_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(rp.p_retailprice) AS total_retail_price,
    COUNT(DISTINCT swmp.s_suppkey) AS active_suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier swmp ON n.n_nationkey = swmp.s_nationkey
JOIN 
    suppliers_with_multiple_parts swmp2 ON swmp.s_suppkey = swmp2.s_suppkey
JOIN 
    customer_orders co ON swmp2.part_count > 0
JOIN 
    ranked_parts rp ON rp.pricing_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC, total_retail_price DESC;
