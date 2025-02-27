WITH supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance'
            WHEN s.s_acctbal < 1000 THEN 'Low Balance'
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
            ELSE 'High Balance' 
        END AS balance_category,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                             WHEN s.s_acctbal IS NULL THEN 'No Balance'
                                             WHEN s.s_acctbal < 1000 THEN 'Low Balance'
                                             WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
                                             ELSE 'High Balance' 
                                         END 
                            ORDER BY s.s_acctbal DESC) AS rank_within_category
    FROM 
        supplier s
    WHERE 
        s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name IN ('FRANCE', 'GERMANY'))
),
part_filter AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    HAVING 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 10) 
        OR p.p_brand = 'Brand#23'
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
),
final_results AS (
    SELECT 
        s.s_name,
        p.p_name,
        co.c_name,
        COALESCE(co.total_orders, 0) AS total_orders,
        COALESCE(co.total_spent, 0) AS total_spent,
        COUNT(DISTINCT l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        supplier_details s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    JOIN 
        part_filter p ON l.l_partkey = p.p_partkey
    FULL OUTER JOIN 
        customer_orders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%' || s.s_name || '%' LIMIT 1)
    WHERE 
        s.rank_within_category <= 5
    GROUP BY 
        s.s_name, p.p_name, co.c_name
    HAVING 
        revenue > (SELECT AVG(l2.l_extendedprice) FROM lineitem l2 WHERE l2.l_discount < 0.05)
)
SELECT 
    f.s_name AS supplier_name,
    f.p_name AS part_name,
    COUNT(f.total_orders) AS order_count,
    SUM(f.total_spent) AS total_money_spent,
    MAX(f.revenue) AS highest_revenue
FROM 
    final_results f
WHERE 
    f.total_orders IS NOT NULL
GROUP BY 
    f.s_name, f.p_name
ORDER BY 
    highest_revenue DESC, order_count DESC;
