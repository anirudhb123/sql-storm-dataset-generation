WITH RECURSIVE supplier_rank AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS product_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank_order
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
nation_part AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(CASE WHEN p.p_type LIKE 'wood%' THEN 1 ELSE 0 END) AS wood_product_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name,
    COALESCE(sr.rank_order, 'No Suppliers') AS supplier_rank,
    COALESCE(os.total_spent, 0) AS customer_spent,
    np.wood_product_count
FROM 
    nation_part np
FULL OUTER JOIN 
    supplier_rank sr ON np.n_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
FULL OUTER JOIN 
    order_summary os ON os.c_custkey = (SELECT MIN(c_custkey) FROM customer WHERE c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA'))
WHERE 
    (np.wood_product_count > 0 OR (np.wood_product_count IS NULL AND sr.rank_order IS NOT NULL))
    AND os.total_spent > 0
ORDER BY 
    np.wood_product_count DESC, 
    supplier_rank DESC;
