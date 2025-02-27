WITH regional_sales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    GROUP BY
        r.r_name
),
customer_activity AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS customer_total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
ranked_customers AS (
    SELECT
        ca.c_custkey,
        ca.customer_total_spent,
        ca.orders_count,
        RANK() OVER (ORDER BY ca.customer_total_spent DESC) AS rank
    FROM
        customer_activity ca
)
SELECT
    r.region_name,
    rc.customer_total_spent,
    rc.orders_count,
    CASE 
        WHEN rc.rank IS NULL THEN 'Inactive'
        WHEN rc.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    COUNT(DISTINCT l.l_orderkey) AS distinct_orders_with_discounts,
    COALESCE(SUM(l.l_extendedprice * l.l_discount), 0) AS total_discounted_sales
FROM
    regional_sales r
LEFT JOIN 
    ranked_customers rc ON r.region_name = (
        SELECT r_name
        FROM region r1
        JOIN nation n1 ON r1.r_regionkey = n1.n_regionkey
        JOIN customer c1 ON n1.n_nationkey = c1.c_nationkey
        WHERE c1.c_custkey = rc.c_custkey
        LIMIT 1
    )
LEFT JOIN
    lineitem l ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = rc.c_custkey)
GROUP BY
    r.region_name, rc.customer_total_spent, rc.orders_count, rc.rank
ORDER BY
    r.region_name ASC, customer_total_spent DESC;
