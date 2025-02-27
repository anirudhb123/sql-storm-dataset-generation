WITH RecursiveCTE AS (
    SELECT
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rn
    FROM
        lineitem
    WHERE
        l_shipdate >= '1997-01-01'
    GROUP BY
        l_orderkey
),
SupplierCTE AS (
    SELECT
        s_nationkey,
        AVG(s_acctbal) AS avg_acctbal
    FROM
        supplier
    GROUP BY
        s_nationkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > 1000
)
SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(SUM(co.total_orders), 0) AS total_orders,
    COALESCE(AVG(s.avg_acctbal), 0) AS avg_supplier_balance,
    COUNT(DISTINCT rc.l_orderkey) AS total_revenue_orders
FROM
    region r
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    SupplierCTE s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    CustomerOrders co ON co.c_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = n.n_nationkey
        ORDER BY c.c_acctbal DESC
        LIMIT 1
    )
LEFT JOIN
    RecursiveCTE rc ON rc.l_orderkey = co.c_custkey
GROUP BY
    r.r_name, n.n_name
ORDER BY
    region_name, nation_name;