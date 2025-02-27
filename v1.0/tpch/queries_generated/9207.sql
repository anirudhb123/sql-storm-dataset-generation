WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.total_sales,
        r.sales_rank
    FROM RankedOrders r
    WHERE r.sales_rank <= 10
),
CustomerSales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(to.total_sales) AS customer_total
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN TopOrders to ON o.o_orderkey = to.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT
    cs.c_custkey,
    cs.c_name,
    cs.customer_total,
    RANK() OVER (ORDER BY cs.customer_total DESC) AS total_sales_rank
FROM CustomerSales cs
WHERE cs.customer_total > 1000
ORDER BY total_sales_rank, cs.c_custkey;
