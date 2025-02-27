WITH RECURSIVE national_sales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
    
    UNION ALL
    
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        n.n_nationkey < (
            SELECT MAX(n2.n_nationkey) 
            FROM nation n2
        )
    GROUP BY 
        n.n_nationkey, n.n_name
),
sales_ranked AS (
    SELECT
        n.n_name,
        ns.total_sales,
        RANK() OVER (ORDER BY ns.total_sales DESC) as sales_rank
    FROM 
        national_sales ns
    JOIN 
        nation n ON ns.n_nationkey = n.n_nationkey
)

SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COALESCE(STRING_AGG(DISTINCT CONCAT(c.c_name, '(', c.c_acctbal, ')') ORDER BY c.c_acctbal), 'No Customers') AS customer_info,
    CASE 
        WHEN sr.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_total_sales
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    sales_ranked sr ON sr.total_sales > 10000
GROUP BY 
    s.s_name, p.p_name, sr.sales_rank
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    supplier_total_sales DESC, p.p_name;
