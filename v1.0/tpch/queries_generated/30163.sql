WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.nationkey AS parent_nationkey,
        0 AS level
    FROM 
        supplier s
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.nationkey,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON s.nationkey = sh.parent_nationkey
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
),
total_lineitem AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(total.l.total_price) AS total_order_value,
    AVG(s.s_acctbal) AS avg_supplier_acctbal
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN 
    ranked_orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    total_lineitem total ON o.o_orderkey = total.l_orderkey
WHERE 
    r.r_name IS NOT NULL 
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_order_value DESC
LIMIT 10;
