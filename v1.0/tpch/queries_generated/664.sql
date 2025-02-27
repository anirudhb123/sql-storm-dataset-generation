WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(ps.ps_partkey) AS PartCount
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS OrderCount
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
PartDetail AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        AVG(l.l_extendedprice) AS AvgPrice,
        COUNT(l.l_orderkey) AS OrdersCount
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_brand
)
SELECT
    coalesce(cs.c_name, 'Unknown Customer') AS CustomerName,
    ps.s_name AS SupplierName,
    pd.p_name AS PartName,
    pd.AvgPrice AS AveragePrice,
    ro.o_orderstatus AS OrderStatus,
    COUNT(DISTINCT ro.o_orderkey) AS TotalOrders,
    SUM(cs.TotalSpent) AS TotalSpentByCustomer,
    SUM(ss.TotalSupplyCost) AS TotalSupplierCosts
FROM
    CustomerStats cs
LEFT JOIN
    RankedOrders ro ON cs.OrderCount > 0
LEFT JOIN
    SupplierSummary ss ON ss.PartCount > 0
LEFT JOIN
    PartDetail pd ON pd.OrdersCount > 0
WHERE
    ro.OrderRank <= 5
GROUP BY
    cs.c_name, ps.s_name, pd.p_name, ro.o_orderstatus
HAVING
    SUM(ss.TotalSupplyCost) IS NOT NULL
ORDER BY
    TotalSpentByCustomer DESC, AveragePrice ASC;
