WITH CTE_Supplier_Stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(s.s_acctbal) AS average_acctbal,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_Most_Reviewed AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COUNT(l.l_orderkey) DESC) AS rn
    FROM 
        part p
    INNER JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CTE_Customer_Account AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    s.*,
    cs.total_spent AS customer_spent,
    cs.order_count AS customer_order_count,
    p.p_name AS most_reviewed_part
FROM 
    CTE_Supplier_Stats s
FULL OUTER JOIN 
    CTE_Customer_Account cs ON s.total_orders = cs.order_count
LEFT JOIN 
    CTE_Most_Reviewed p ON p.rn = 1 
WHERE 
    s.total_available IS NOT NULL 
    OR cs.total_spent > 1000
ORDER BY 
    COALESCE(s.s_name, 'Unknown Supplier'), 
    cs.total_spent DESC,
    CASE WHEN s.average_acctbal IS NULL THEN 0 ELSE s.average_acctbal END,
    p.p_name;
