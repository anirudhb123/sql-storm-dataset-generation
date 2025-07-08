
WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
avg_order_values AS (
    SELECT 
        o.o_custkey,
        AVG(o.o_totalprice) AS avg_total_price
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
), 
sized_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        CASE WHEN p.p_size >= 10 THEN 'Large'
             WHEN p.p_size BETWEEN 5 AND 9 THEN 'Medium'
             ELSE 'Small' END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p1.p_retailprice) 
            FROM part p1 
            WHERE p1.p_size < 5
        )
), 
order_stats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ss.n_name AS supplier_nation,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.total_price) AS total_revenue,
    AVG(a.avg_total_price) AS avg_customer_order_value,
    LISTAGG(DISTINCT CONCAT(p.p_name, ' : ', p.p_size), '; ') WITHIN GROUP (ORDER BY p.p_name) AS part_details
FROM 
    ranked_suppliers ss
LEFT JOIN 
    partsupp ps ON ss.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    sized_parts p ON ps.ps_partkey = p.p_partkey
JOIN 
    order_stats l ON ps.ps_partkey = l.l_orderkey
JOIN 
    avg_order_values a ON l.l_orderkey = a.o_custkey
WHERE 
    p.size_category = 'Large' 
    AND ss.rank = 1
GROUP BY 
    ss.s_suppkey, ss.s_name, ss.s_acctbal, ss.rank, ss.n_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC,
    supplier_nation;
