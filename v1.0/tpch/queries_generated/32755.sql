WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
    UNION ALL
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(o.o_totalprice) AS total_sales
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name AS Nation,
    COALESCE(SUM(ns.total_sales), 0) AS Total_Sales,
    COUNT(DISTINCT c.c_custkey) AS Unique_Customers,
    (SELECT AVG(c.c_acctbal) 
     FROM customer c 
     WHERE c.c_nationkey = n.n_nationkey AND c.c_acctbal IS NOT NULL) AS Avg_Account_Balance,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ns.total_sales), 0) DESC) AS Sales_Rank
FROM 
    nation n
LEFT JOIN 
    nation_sales ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
GROUP BY 
    n.n_nationkey, n.n_name
ORDER BY 
    Total_Sales DESC, n.n_name
LIMIT 10;
