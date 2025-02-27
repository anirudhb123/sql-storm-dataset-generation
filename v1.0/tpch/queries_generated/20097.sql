WITH RECURSIVE supplier_ranking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, c.c_name
    HAVING 
        SUM(l.l_quantity) > ALL (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_linenumber > 0)
),
filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_size,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown Price'
            WHEN p.p_retailprice < 100 THEN 'Low Price'
            WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'Medium Price'
            ELSE 'High Price'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_comment NOT LIKE '%defective%'
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(hv.total_revenue) AS avg_revenue,
    STRING_AGG(DISTINCT fp.price_category, ', ') AS price_categories
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier_ranking sr ON n.n_nationkey = sr.s_nationkey AND sr.rank <= 5
LEFT JOIN 
    high_value_orders hv ON hv.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'O')
LEFT JOIN 
    filtered_parts fp ON fp.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sr.s_suppkey)
WHERE 
    sr.s_suppkey IS NOT NULL OR hv.total_revenue IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0 AND AVG(hv.total_revenue) IS NOT NULL
ORDER BY 
    region;
