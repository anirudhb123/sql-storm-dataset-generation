WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        orders AS o
    JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp AS ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier AS s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation AS n ON s.s_nationkey = n.n_nationkey
    WHERE
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate <= DATE '2023-12-31'
    GROUP BY
        n.n_name
),
TopNations AS (
    SELECT
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
),
CustomerSales AS (
    SELECT
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total_sales
    FROM
        customer AS c
    JOIN orders AS o ON c.c_custkey = o.o_custkey
    JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate <= DATE '2023-12-31'
    GROUP BY
        c.c_name
)
SELECT
    t.nation_name,
    t.total_sales,
    c.c_name,
    COALESCE(c.customer_total_sales, 0) AS customer_sales,
    t.sales_rank
FROM
    TopNations AS t
LEFT JOIN CustomerSales AS c ON t.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey LIMIT 1) LIMIT 1))))
ORDER BY
    t.sales_rank, customer_sales DESC;
