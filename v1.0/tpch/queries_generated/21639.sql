WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND GETDATE()
    GROUP BY
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(ro.total_sales) AS customer_total_sales
    FROM
        customer c
    JOIN
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    WHERE
        ro.rn = 1
    GROUP BY
        c.c_custkey, c.c_name
),
RegionSupplier AS (
    SELECT
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        r.r_name, s.s_name
)
SELECT
    tc.c_name,
    rsc.region_name,
    tc.customer_total_sales,
    rsc.total_supply_cost,
    CASE
        WHEN tc.customer_total_sales > 10000 THEN 'High Value'
        WHEN tc.customer_total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(rsc.total_supply_cost, 0) AS adjusted_supply_cost
FROM
    TopCustomers tc
LEFT JOIN
    RegionSupplier rsc ON 1 = 1  -- Cross join to show all regions per customer
WHERE
    tc.customer_total_sales IS NOT NULL
ORDER BY
    tc.customer_total_sales DESC,
    rsc.region_name ASC;
