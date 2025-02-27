WITH CTE_Supplier_Sales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CTE_Customer_Balances AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown Balance'
            WHEN c.c_acctbal <= 0 THEN 'Zero or Negative'
            ELSE 'Positive Balance'
        END AS balance_status
    FROM
        customer c
),
CTE_Product_Count AS (
    SELECT
        p.p_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey
)
SELECT
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COALESCE(cte.total_sales, 0) AS total_sales,
    cte.order_count,
    SUBSTRING(n.r_comment, POSITION('important' IN n.r_comment) + 1 FOR 50) AS important_comment_segment,
    CASE 
        WHEN cte.sales_rank = 1 THEN 'Top Supplier'
        ELSE NULL
    END AS supplier_status,
    p.p_name,
    p.p_size,
    pc.supplier_count,
    CASE 
        WHEN COUNT(DISTINCT l.l_orderkey) > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buying_habit
FROM
    nation n
LEFT JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN
    CTE_Supplier_Sales cte ON s.s_suppkey = cte.s_suppkey
JOIN
    lineitem l ON l.l_suppkey = s.s_suppkey
JOIN
    CTE_Product_Count pc ON pc.supplier_count > 3
GROUP BY
    n.n_name, s.s_name, c.c_name, cte.total_sales, cte.order_count, n.r_comment, cte.sales_rank, p.p_name, p.p_size, pc.supplier_count
HAVING
    COALESCE(cte.total_sales, 0) > 1000 AND 
    (n.n_name LIKE '%land%' OR s.s_name NOT LIKE 'A%')
ORDER BY
    total_sales DESC NULLS LAST;
