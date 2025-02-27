WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        1 AS level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT 
        sh.c_custkey,
        sh.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        orders o ON sh.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'A'
),
agg_sales AS (
    SELECT 
        s.c_custkey,
        SUM(s.o_totalprice) AS total_sales,
        COUNT(DISTINCT s.o_orderkey) AS num_orders
    FROM 
        sales_hierarchy s
    GROUP BY 
        s.c_custkey
),
final_sales AS (
    SELECT 
        sh.c_custkey,
        p.p_partkey,
        p.p_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        AVG(li.l_discount) AS avg_discount,
        ROW_NUMBER() OVER (PARTITION BY li.l_partkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rank,
        CASE
            WHEN SUM(li.l_extendedprice * (1 - li.l_discount)) IS NULL THEN 'No Sales'
            WHEN COUNT(li.l_orderkey) > 10 THEN 'Frequent Buyer'
            ELSE 'One-time buyer'
        END AS buyer_type
    FROM 
        lineitem li
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    JOIN 
        sales_hierarchy sh ON o.o_custkey = sh.c_custkey
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        li.l_returnflag = 'N'
    GROUP BY 
        sh.c_custkey, p.p_partkey, p.p_name
)
SELECT 
    fs.c_custkey,
    fs.total_revenue,
    fs.avg_discount,
    fs.buyer_type,
    COUNT(DISTINCT fs.p_partkey) AS unique_parts_sold,
    MAX(fs.rank) AS top_product_rank
FROM 
    final_sales fs
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = fs.c_custkey))
GROUP BY 
    fs.c_custkey, fs.total_revenue, fs.avg_discount, fs.buyer_type
HAVING 
    fs.total_revenue IS NOT NULL OR fs.buyer_type = 'One-time buyer'
ORDER BY 
    fs.total_revenue DESC NULLS LAST
LIMIT 100;
