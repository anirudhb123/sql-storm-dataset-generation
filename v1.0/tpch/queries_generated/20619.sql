WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey, 
        s.s_comment,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (
            SELECT AVG(su.s_acctbal) FROM supplier su WHERE su.s_acctbal IS NOT NULL
        )
    UNION ALL
    SELECT 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey, 
        s.s_comment,
        sh.level + 1
    FROM 
        supplier_hierarchy sh
    JOIN 
        partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        sh.level < 5
),
customer_summary AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
region_average AS (
    SELECT 
        r.r_regionkey, 
        AVG(o.o_totalprice) AS avg_price
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    sh.s_name AS supplier_name,
    cs.total_spent,
    cs.order_count,
    ra.avg_price,
    sh.level
FROM 
    supplier_hierarchy sh
JOIN 
    customer_summary cs ON sh.s_nationkey = cs.c_custkey
LEFT JOIN 
    region_average ra ON ra.r_regionkey = sh.s_nationkey
WHERE 
    cs.order_count > 5 OR (sh.level < 3 AND cs.total_spent IS NOT NULL)
ORDER BY 
    sh.level DESC, cs.total_spent DESC
LIMIT 100
OFFSET (
    SELECT COUNT(*) 
    FROM customer_summary 
    WHERE total_spent IS NOT NULL 
      AND total_spent <= (
          SELECT MAX(total_spent) 
          FROM customer_summary 
          WHERE order_count > 10
      )
)
