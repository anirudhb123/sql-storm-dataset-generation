WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
total_order_sales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
regional_stats AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    p.p_name,
    IFNULL(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(r.avg_acctbal, 0) AS avg_supplier_balance,
    MAX(ts.total_sales) AS max_order_value,
    JSON_ARRAYAGG(s.s_name) AS suppliers
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    ranked_suppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank = 1
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    total_order_sales ts ON l.l_orderkey = ts.o_orderkey
LEFT JOIN 
    regional_stats r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = s.s_suppkey))
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
