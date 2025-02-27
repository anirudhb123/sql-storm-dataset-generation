WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_a.s_acctbal) FROM supplier s_a)

    UNION ALL

    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal > sh.level * 1000
),

part_sales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),

customer_sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),

order_status AS (
    SELECT 
        o.o_orderstatus, 
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_orderstatus
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier_name,
    COALESCE(ps.total_sales, 0) AS total_sales,
    cs.order_count,
    cs.total_spent,
    os.order_count AS status_count,
    os.avg_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    part_sales ps ON s.s_suppkey = ps.p_partkey
LEFT JOIN 
    customer_sales cs ON s.s_nationkey = cs.c_custkey
LEFT JOIN 
    order_status os ON os.o_orderstatus = CASE WHEN cs.total_spent > 1000 THEN 'O' ELSE 'F' END
WHERE 
    s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_comment IS NOT NULL)
ORDER BY 
    total_sales DESC, cs.total_spent DESC
LIMIT 10;
