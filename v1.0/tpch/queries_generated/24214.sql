WITH RECURSIVE price_ranks AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_retailprice, 
        RANK() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) as price_rank
    FROM 
        part
),
supplier_aggregate AS (
    SELECT 
        s_nationkey, 
        COUNT(s_suppkey) as total_suppliers, 
        SUM(s_acctbal) AS total_account_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
national_orders AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
),
lineitem_summary AS (
    SELECT 
        l_partkey, 
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        COUNT(*) FILTER (WHERE l_returnflag = 'R') AS returns_count
    FROM 
        lineitem
    GROUP BY 
        l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COALESCE(l.returns_count, 0) AS returns_count,
    CASE 
        WHEN s.total_suppliers IS NULL THEN 'Unknown'
        ELSE s.total_suppliers::TEXT
    END AS supplier_count,
    CASE 
        WHEN n.order_count IS NULL THEN 'No Orders'
        ELSE n.order_count::TEXT
    END AS order_count,
    r.r_name
FROM 
    part p
LEFT JOIN 
    lineitem_summary l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier_aggregate s ON p.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_nationkey)
LEFT JOIN 
    national_orders n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON s.s_nationkey = r.r_regionkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
ORDER BY 
    total_revenue DESC NULLS LAST
LIMIT 50;
