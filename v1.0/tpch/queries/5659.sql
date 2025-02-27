
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS RegionalRank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        r.r_name = 'ASIA'
),
TopParts AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity
    FROM
        partsupp ps
    JOIN
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    GROUP BY
        ps.ps_partkey
    HAVING
        SUM(ps.ps_availqty) > 1000
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    c.c_name AS CustomerName,
    tp.TotalAvailableQuantity AS AvailablePartsQuantity,
    co.TotalSpent AS TotalSpent,
    c.c_acctbal AS AccountBalance
FROM
    CustomerOrders co
JOIN
    customer c ON co.c_custkey = c.c_custkey
JOIN
    TopParts tp ON tp.ps_partkey IN (
        SELECT
            l.l_partkey
        FROM
            lineitem l
        JOIN
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE
            o.o_orderstatus = 'F'
    )
ORDER BY
    co.TotalSpent DESC, tp.TotalAvailableQuantity DESC
LIMIT 10;
