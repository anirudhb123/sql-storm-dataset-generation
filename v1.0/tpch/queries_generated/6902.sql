WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        SUM(ps.ps_availqty) > 100
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS CustomerRank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > 5000
),
CustomerSupplierInteractions AS (
    SELECT
        c.c_name AS CustomerName,
        s.s_name AS SupplierName,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM
        HighValueCustomers c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        s.s_suppkey IN (SELECT s_suppkey FROM RankedSuppliers)
    GROUP BY
        c.c_name, s.s_name
)
SELECT
    CustomerName,
    SupplierName,
    OrderCount,
    TotalRevenue
FROM
    CustomerSupplierInteractions
ORDER BY
    TotalRevenue DESC, OrderCount DESC;
