WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
CustomTerm AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'UNKNOWN'
            WHEN c.c_acctbal < 5000 THEN 'LOW BALANCE'
            WHEN c.c_acctbal BETWEEN 5000 AND 15000 THEN 'MEDIUM BALANCE'
            ELSE 'HIGH BALANCE'
        END AS balance_category
    FROM 
        customer c
    WHERE 
        c.c_comment LIKE '%turquoise%'
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    ct.balance_category,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN AVG(l.l_discount) > 0.1 
        THEN 'Most orders have a discount'
        ELSE 'Few orders have discounts'
    END AS discount_insight,
    STRING_AGG(DISTINCT COALESCE(sr.s_name, 'N/A'), ', ') AS ranked_suppliers
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers sr ON sr.s_suppkey = s.s_suppkey AND sr.rnk <= 3
JOIN 
    CustomTerm ct ON ct.c_custkey = o.o_custkey
WHERE 
    p.p_retailprice BETWEEN 100 AND 1000
    AND (p.p_comment NOT LIKE '%defect%' OR p.p_comment IS NULL)
GROUP BY
    p.p_partkey, p.p_name, s.s_name, ct.balance_category
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC, p.p_name;
