WITH regional_data AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        nation n
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        n.n_nationkey, n.n_name, r.r_name
),
top_sales AS (
    SELECT
        region_name,
        total_sales,
        total_returned_quantity,
        sales_rank
    FROM
        regional_data
    WHERE
        sales_rank <= 3
),
sales_analysis AS (
    SELECT
        region_name,
        total_sales,
        total_returned_quantity,
        CASE
            WHEN total_sales IS NULL THEN 'No Sales'
            WHEN total_returned_quantity IS NULL THEN 'No Returns'
            ELSE 'Sales Data Available'
        END AS sales_status
    FROM
        top_sales
)
SELECT
    t.region_name,
    t.total_sales,
    t.total_returned_quantity,
    t.sales_status,
    COALESCE(t.total_sales / NULLIF(t.total_returned_quantity, 0), 0) AS sales_to_returns_ratio,
    STRING_AGG(CONCAT_WS(' - ', t.region_name, t.sales_status), ', ') WITHIN GROUP (ORDER BY t.region_name) AS region_summary
FROM
    sales_analysis t
RIGHT JOIN
    region r ON t.region_name = r.r_name
GROUP BY
    r.r_name
ORDER BY
    r.r_name;
