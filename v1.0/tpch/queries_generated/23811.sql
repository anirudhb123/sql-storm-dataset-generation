WITH RECURSIVE cte_order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1993-01-01' 
        AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
cte_partitioned AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        total_revenue,
        total_items,
        CASE 
            WHEN total_revenue > 10000 THEN 'High Value'
            WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS revenue_category,
        RANK() OVER (ORDER BY total_revenue DESC) AS rnk
    FROM 
        cte_order_summary o
)
SELECT 
    o.o_orderstatus,
    SUM(o.total_revenue) AS total_revenue,
    AVG(o.total_items) AS avg_items,
    COUNT(DISTINCT o.o_orderkey) AS unique_orders,
    MAX(o.rnk) AS max_rank
FROM 
    cte_partitioned o
WHERE 
    o.revenue_category = 'High Value' 
    AND o.o_orderstatus IN (SELECT DISTINCT o_orderstatus FROM orders WHERE o_orderstatus IS NOT NULL)
GROUP BY 
    o.o_orderstatus
HAVING 
    SUM(o.total_revenue) > (
        SELECT COALESCE(AVG(total_revenue), 0) 
        FROM cte_partitioned 
        WHERE revenue_category = 'Low Value'
    )
UNION ALL
SELECT 
    r.r_name AS region_name,
    SUM(l.ps_supplycost) AS total_supplycost,
    COUNT(DISTINCT n.n_nationkey) AS unique_nations,
    MAX(COALESCE(s.s_acctbal, 0)) AS max_acctbal
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp l ON s.s_suppkey = l.ps_suppkey
WHERE 
    l.ps_availqty IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    total_supplycost DESC;
