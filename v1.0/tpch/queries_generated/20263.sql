WITH RECURSIVE nation_sales AS (
    SELECT
        n.n_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(o.o_totalprice) DESC) AS rank
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
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate BETWEEN DATEADD(month, -12, CURRENT_DATE) AND CURRENT_DATE
    GROUP BY
        n.n_name
),
filtered_nation_sales AS (
    SELECT
        n_name,
        total_sales,
        unique_customers,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            ELSE CAST(total_sales AS VARCHAR)
        END AS sales_status
    FROM
        nation_sales
    WHERE
        unique_customers > 0
)
SELECT 
    f.n_name,
    f.total_sales,
    f.unique_customers,
    f.sales_status,
    COALESCE((
        SELECT COUNT(DISTINCT l.l_orderkey)
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderstatus = 'F'
          AND l.l_returnflag = 'R'
          AND EXISTS (
              SELECT 1 FROM customer c WHERE c.c_custkey = o.o_custkey AND c.c_acctbal > 1000
          )
    ), 0) AS completed_returned_orders,
    CASE
        WHEN f.total_sales > (SELECT AVG(total_sales) FROM filtered_nation_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM 
    filtered_nation_sales f
LEFT JOIN 
    region r ON (SELECT r_regionkey FROM region WHERE r_name = 'ASIA') = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = f.n_name)
WHERE 
    f.total_sales > 10000 
ORDER BY 
    f.total_sales DESC
LIMIT 10
OFFSET 5;
