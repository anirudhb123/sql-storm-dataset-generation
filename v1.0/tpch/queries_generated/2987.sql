WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
NationSuppliers AS (
    SELECT
        n.n_name,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        n.n_name, s.s_suppkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    COALESCE(c.c_name, 'UNKNOWN CUSTOMER') AS Customer_Name,
    COALESCE(so.s_name, 'No Supplier') AS Supplier_Name,
    r.o_orderkey AS Order_Key,
    ro.o_orderdate AS Order_Date,
    ro.o_totalprice AS Total_Price,
    ns.total_supply_value AS Total_Supply_Value,
    CASE 
        WHEN ro.order_rank <= 5 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS Order_Category
FROM
    RankedOrders ro
LEFT JOIN
    CustomerOrders c ON ro.o_orderkey = c.c_custkey
OUTER APPLY (
    SELECT TOP 1 s.s_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_retailprice > 100
    )
    ORDER BY s.s_acctbal DESC
) AS so
JOIN NationSuppliers ns ON so.s_suppkey = ns.s_suppkey
WHERE
    ns.total_supply_value IS NOT NULL
ORDER BY
    ro.o_orderdate DESC, Total_Price DESC;
