WITH RECURSIVE national_stats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name

    UNION ALL

    SELECT 
        n.n_nationkey,
        n.n_name,
        ns.total_acctbal + SUM(s.s_acctbal),
        ns.customer_count + COUNT(DISTINCT c.c_custkey)
    FROM 
        nation n
    JOIN 
        national_stats ns ON n.n_nationkey = ns.n_nationkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, ns.total_acctbal, ns.customer_count
),
part_order_stats AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        COUNT(li.l_orderkey) AS order_count,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ns.n_name AS nation_name,
    ps.p_name AS part_name,
    ps.order_count,
    ps.total_sales,
    ns.total_acctbal,
    ns.customer_count,
    CASE 
        WHEN ps.order_count > 10 THEN 'High Demand' 
        ELSE 'Low Demand' 
    END AS demand_category
FROM 
    national_stats ns
FULL OUTER JOIN 
    part_order_stats ps ON ns.n_nationkey = (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_name = ps.p_name) 
WHERE 
    ns.total_acctbal IS NOT NULL 
    OR ps.order_count > 0
ORDER BY 
    ns.customer_count DESC, ps.total_sales DESC;
