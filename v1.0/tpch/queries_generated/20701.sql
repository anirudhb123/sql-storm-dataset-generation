WITH RECURSIVE price_variance AS (
    SELECT 
        p_partkey, 
        p_name,
        p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS price_rank,
        LEAD(p_retailprice) OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS higher_price,
        LAG(p_retailprice) OVER (PARTITION BY p_mfgr ORDER BY p_retailprice) AS lower_price
    FROM 
        part
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
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
customer_with_discount AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_discount) > 0.1
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.mfgr_discrepancy,
    n.n_name AS nation_name,
    ns.supplier_count,
    os.total_revenue,
    cd.discounted_total,
    CASE 
        WHEN price_rank = 1 THEN 'Highest Price'
        ELSE 'Other Prices' 
    END AS price_category
FROM 
    price_variance p
JOIN 
    nation_supplier ns ON ns.n_nationkey = (SELECT n_regionkey FROM nation WHERE n_name = p.p_mfgr LIMIT 1)
LEFT JOIN 
    order_summary os ON os.total_revenue = (SELECT MAX(total_revenue) FROM order_summary)
LEFT JOIN 
    customer_with_discount cd ON cd.discounted_total < (SELECT AVG(discounted_total) FROM customer_with_discount WHERE discounted_total IS NOT NULL)
WHERE 
    p.p_retailprice > COALESCE(cd.discounted_total, 0)
ORDER BY 
    p.p_partkey DESC, os.total_revenue ASC;
