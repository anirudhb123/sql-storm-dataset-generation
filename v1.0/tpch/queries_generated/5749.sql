WITH RegionalSales AS (
    SELECT
        r.r_name AS region,
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
    GROUP BY
        r.r_name
),
CustomerAnalysis AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
Summary AS (
    SELECT
        r.region,
        COUNT(c.c_custkey) AS customer_count,
        SUM(s.total_sales) AS region_sales,
        AVG(c.total_spent) AS avg_customer_spent,
        MAX(c.order_count) AS max_orders_by_customer
    FROM
        RegionalSales s
    LEFT JOIN
        CustomerAnalysis c ON s.region = c.region
    GROUP BY
        r.region
)
SELECT
    r.region,
    COALESCE(c.customer_count, 0) AS customer_count,
    COALESCE(r.region_sales, 0) AS region_sales,
    COALESCE(c.avg_customer_spent, 0) AS avg_customer_spent,
    COALESCE(c.max_orders_by_customer, 0) AS max_orders_by_customer
FROM
    (SELECT DISTINCT r.r_name AS region FROM region r) r
LEFT JOIN
    Summary c ON r.region = c.region
ORDER BY
    r.region;
