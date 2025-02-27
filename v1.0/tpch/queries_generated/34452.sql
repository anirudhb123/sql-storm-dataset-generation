WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c_acctbal)
        FROM customer
    )
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = 'UNITED STATES'
    )
    WHERE sh.level < 3
),
order_details AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT
    sh.c_name,
    sh.c_acctbal,
    od.o_orderkey,
    od.total_sales,
    od.o_orderdate
FROM sales_hierarchy sh
LEFT OUTER JOIN order_details od ON sh.c_custkey = (
    SELECT c.c_custkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderkey = od.o_orderkey
    LIMIT 1
)
WHERE od.total_sales > 500
ORDER BY sh.c_acctbal DESC, od.o_orderdate DESC
LIMIT 10;
