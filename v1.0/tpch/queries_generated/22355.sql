WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
nation_supplier AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
order_summaries AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_quantity * (l.l_extendedprice * (1 - l.l_discount))) AS total_value,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
filtered_orders AS (
    SELECT 
        os.o_orderkey, 
        os.total_value,
        os.o_orderdate,
        CASE 
            WHEN os.total_value > 100000 THEN 'High Value'
            WHEN os.total_value BETWEEN 50000 AND 100000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS order_category
    FROM 
        order_summaries os
    WHERE 
        os.o_orderdate >= '2021-01-01' 
),
combined_summary AS (
    SELECT 
        np.supplier_count,
        rp.p_partkey, 
        rp.p_name, 
        rp.price_rank,
        fo.order_category,
        COALESCE(SUM(fo.total_value), 0) AS total_order_value
    FROM 
        ranked_parts rp
    FULL OUTER JOIN 
        nation_supplier np ON np.n_nationkey = rp.p_partkey 
    LEFT JOIN 
        filtered_orders fo ON fo.o_orderkey = rp.p_partkey
    GROUP BY 
        np.supplier_count, rp.p_partkey, rp.p_name, rp.price_rank, fo.order_category
)
SELECT 
    cs.p_partkey,
    cs.p_name,
    cs.price_rank,
    cs.supplier_count,
    cs.order_category,
    CASE 
        WHEN cs.total_order_value IS NULL THEN 'No Orders'
        ELSE CAST(cs.total_order_value AS varchar)
    END AS total_order_value,
    STRING_AGG(DISTINCT cs.order_category, ', ') AS order_categories
FROM 
    combined_summary cs
GROUP BY 
    cs.p_partkey, cs.p_name, cs.price_rank, cs.supplier_count
ORDER BY 
    cs.price_rank ASC, cs.supplier_count DESC;
