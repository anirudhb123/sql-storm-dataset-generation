WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'O'
        AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
TopCustomerOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        n.n_name AS nation_name
    FROM
        RankedOrders ro
    JOIN
        nation n ON ro.rank = 1 AND n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = ro.c_name LIMIT 1)
)
SELECT
    tco.o_orderkey,
    tco.o_orderdate,
    tco.o_totalprice,
    tco.c_name,
    tco.nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    SUM(l.l_quantity) AS total_quantity
FROM
    TopCustomerOrders tco
JOIN
    lineitem l ON tco.o_orderkey = l.l_orderkey
GROUP BY
    tco.o_orderkey, tco.o_orderdate, tco.o_totalprice, tco.c_name, tco.nation_name
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY
    tco.o_totalprice DESC
LIMIT 10;