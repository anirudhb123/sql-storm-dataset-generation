WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
high_value_customers AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
),
supplier_part_availability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0
),
suspicious_suppliers AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        s.s_acctbal < 500 AND 
        (s.s_comment LIKE '%suspicious%' OR s.s_comment LIKE '%fake%')
    GROUP BY 
        s.s_suppkey
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) <= 2
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(s.total_availqty, 0) AS available_quantity,
    r.total_spent AS customer_spending,
    CASE 
        WHEN r.total_spent IS NULL THEN 'No Spend' 
        ELSE CAST(r.total_spent AS VARCHAR(20)) 
    END AS spending_status,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
LEFT JOIN 
    supplier_part_availability s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    ranked_orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    high_value_customers r ON o.o_custkey = r.c_custkey
LEFT JOIN 
    suspicious_suppliers ss ON ss.s_suppkey = l.l_suppkey
WHERE 
    (p.p_retailprice BETWEEN 10.00 AND 100.00 OR 
    p.p_container LIKE '%BOX%')
    AND (o.o_orderstatus IS NULL OR o.o_orderstatus IN ('F', 'O'))
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, r.total_spent
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    customer_spending DESC, available_quantity ASC;
