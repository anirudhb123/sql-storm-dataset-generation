WITH RECURSIVE nation_sales AS (
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
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
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
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2022-12-31'
        AND n.n_nationkey NOT IN (SELECT n_nationkey FROM nation_sales)
    GROUP BY 
        n.n_nationkey, n.n_name
),
ranked_sales AS (
    SELECT 
        n.n_name,
        ns.total_sales,
        RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM 
        nation_sales ns
    JOIN 
        nation n ON ns.n_nationkey = n.n_nationkey
    WHERE 
        ns.total_sales IS NOT NULL
)
SELECT 
    r.r_name,
    COALESCE(rs.sales_rank, 0) AS sales_rank,
    COALESCE(rs.total_sales, 0) AS total_sales
FROM 
    region r
LEFT JOIN 
    ranked_sales rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.n_nationkey LIMIT 1)
WHERE 
    r.r_name LIKE '%East%'
ORDER BY 
    r.r_name, sales_rank;
