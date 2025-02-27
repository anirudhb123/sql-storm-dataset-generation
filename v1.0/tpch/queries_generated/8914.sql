WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'O'
),
TopNationOrders AS (
    SELECT
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM
        RankedOrders o
    JOIN
        nation n ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
    WHERE
        o.order_rank <= 5
    GROUP BY
        n.n_name
),
TopRegions AS (
    SELECT
        r.r_name,
        SUM(t.total_sales) AS region_sales
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        TopNationOrders t ON n.n_name = t.n_name
    GROUP BY
        r.r_name
)
SELECT
    r.r_name,
    r.region_sales,
    RANK() OVER (ORDER BY r.region_sales DESC) AS sales_rank
FROM
    TopRegions r
WHERE
    r.region_sales > (SELECT AVG(region_sales) FROM TopRegions)
ORDER BY
    r.region_sales DESC;
