WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
),
sales_ranked AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
)
SELECT 
    sr.region_name,
    sr.total_sales,
    sr.sales_rank,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    AVG(c.c_acctbal) AS avg_customer_balance
FROM 
    sales_ranked sr
JOIN 
    nation n ON sr.region_name = (SELECT r.r_name FROM region r WHERE r.r_regionkey = n.n_regionkey)
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    sr.region_name, sr.total_sales, sr.sales_rank
ORDER BY 
    sr.sales_rank;