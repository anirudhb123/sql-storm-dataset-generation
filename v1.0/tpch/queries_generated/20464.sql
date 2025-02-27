WITH RECURSIVE part_hierarchy AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        CASE 
            WHEN p.p_size IS NULL THEN 'Not Specified' 
            WHEN p.p_size < 10 THEN 'Small' 
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium' 
            ELSE 'Large' 
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
    UNION ALL
    SELECT 
        p2.p_partkey,
        p2.p_name,
        p2.p_size,
        CASE 
            WHEN p2.p_size IS NULL THEN 'Not Specified' 
            WHEN p2.p_size < 10 THEN 'Small' 
            WHEN p2.p_size BETWEEN 10 AND 20 THEN 'Medium' 
            ELSE 'Large' 
        END AS size_category
    FROM 
        part p2
    JOIN 
        part_hierarchy ph ON ph.p_partkey = p2.p_partkey
    WHERE 
        p2.p_size IS NOT NULL
),
nation_stats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
order_stats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
ranked_orders AS (
    SELECT 
        os.o_orderkey,
        os.order_total,
        ROW_NUMBER() OVER (PARTITION BY os.o_orderdate ORDER BY os.order_total DESC) AS order_rank
    FROM 
        order_stats os
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.size_category,
    ns.supplier_count,
    ns.total_account_balance,
    ro.order_total,
    ro.order_rank
FROM 
    part_hierarchy ph
LEFT JOIN 
    nation_stats ns ON ns.n_nationkey = (
        SELECT 
            n.n_nationkey 
        FROM 
            nation n
        WHERE 
            n.n_name ILIKE ANY(ARRAY['%land%', '%ia%', '%ia%', '%an%', '%stan%']) 
        LIMIT 1
    )
FULL OUTER JOIN 
    ranked_orders ro ON ro.o_orderkey = (
        SELECT 
            MIN(o.o_orderkey) 
        FROM 
            orders o
        WHERE 
            o.o_orderstatus NOT IN ('C', 'P') 
            AND o.o_ordertotal > (SELECT AVG(o2.o_totalprice) FROM orders o2)
        ORDER BY 
            o.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    (ph.p_size IS NULL OR ph.p_size >= 10) 
    AND (ns.total_account_balance IS NOT NULL OR ph.p_partkey < 1000)
ORDER BY 
    ph.p_partkey, ns.supplier_count DESC, ro.order_rank
FETCH FIRST 100 ROWS ONLY;
