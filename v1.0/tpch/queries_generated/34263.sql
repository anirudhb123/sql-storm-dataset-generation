WITH RECURSIVE RegionalSales AS (
    SELECT 
        r_name AS region, 
        SUM(o.o_totalprice) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r_name
    UNION ALL
    SELECT 
        r_name,
        total_sales * 1.1 AS total_sales,
        NULL AS rank
    FROM 
        RegionalSales
    WHERE 
        rank IS NOT NULL AND total_sales < 50000
)
SELECT 
    r.r_name, 
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
    COALESCE(MAX(s.s_acctbal), 0) AS max_supplier_balance,
    AVG(l.l_quantity) AS average_quantity,
    (SELECT COUNT(DISTINCT o.o_orderkey) FROM orders o WHERE o.o_orderstatus = 'O') AS active_orders,
    CASE WHEN COUNT(DISTINCT l.l_orderkey) > 0 
         THEN SUM(l.l_extendedprice * (1 - l.l_discount))
         ELSE 0 
    END AS total_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    r.r_name LIKE '%West%'
GROUP BY 
    r.r_name
HAVING 
    SUM(l.l_quantity) IS NOT NULL
ORDER BY 
    max_supplier_balance DESC;
