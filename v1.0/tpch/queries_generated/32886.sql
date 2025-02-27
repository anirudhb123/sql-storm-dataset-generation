WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        n.n_name
),
average_sales AS (
    SELECT 
        AVG(total_sales) as avg_sales
    FROM 
        nation_sales
),
rich_nations AS (
    SELECT 
        ns.nation_name,
        ns.total_sales,
        CASE 
            WHEN ns.total_sales > (SELECT avg_sales FROM average_sales) THEN 'Above Average'
            ELSE 'Below Average'
        END AS sales_status
    FROM 
        nation_sales ns
    WHERE 
        ns.sales_rank <= 5
)
SELECT 
    rn.nation_name,
    rn.total_sales,
    rn.sales_status,
    COUNT(DISTINCT l.l_orderkey) AS orders_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_items
FROM 
    rich_nations rn
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = rn.nation_name)))
GROUP BY 
    rn.nation_name, rn.total_sales, rn.sales_status
ORDER BY 
    rn.total_sales DESC;
