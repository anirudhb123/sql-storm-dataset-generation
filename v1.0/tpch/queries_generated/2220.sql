WITH regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        n.n_name
),
discounted_sales AS (
    SELECT 
        nation_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
),
top_nations AS (
    SELECT 
        nation_name,
        total_sales,
        order_count
    FROM 
        discounted_sales
    WHERE 
        sales_rank <= 5
)
SELECT 
    t.nation_name,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(t.order_count, 0) AS order_count,
    (SELECT COUNT(DISTINCT s.s_suppkey)
     FROM supplier s
     WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = t.nation_name)
     AND s.s_acctbal IS NOT NULL) AS supplier_count
FROM 
    top_nations t
FULL OUTER JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = t.nation_name)
WHERE 
    r.r_name IS NOT NULL OR t.nation_name IS NOT NULL
ORDER BY 
    t.total_sales DESC;
