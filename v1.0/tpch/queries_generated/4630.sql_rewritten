WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM
        orders o
    WHERE
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    GROUP BY
        s.s_suppkey, s.s_name
),
TopNations AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(c.c_custkey) AS customer_count
    FROM
        nation n
    LEFT JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY
        n.n_nationkey, n.n_name
    HAVING
        COUNT(c.c_custkey) > 10
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    sd.s_name,
    sd.total_supplycost,
    tn.n_name AS nation_name,
    CASE 
        WHEN ro.o_orderpriority = 'High' THEN 'High Priority'
        WHEN ro.o_orderpriority = 'Medium' THEN 'Medium Priority'
        ELSE 'Low Priority'
    END AS priority_label
FROM
    RankedOrders ro
LEFT JOIN
    SupplierDetails sd ON sd.total_supplycost = (
        SELECT MAX(total_supplycost)
        FROM SupplierDetails
        WHERE sd.s_suppkey = s_suppkey
    )
JOIN
    TopNations tn ON tn.n_nationkey = sd.s_suppkey
WHERE
    ro.rn <= 10
ORDER BY
    ro.o_orderdate DESC, ro.o_totalprice ASC;