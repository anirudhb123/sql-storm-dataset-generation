WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
), CustomerOrderStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalOrderValue
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
), LineItemSummary AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_quantity) AS TotalQuantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
)
SELECT
    r.r_name AS Region,
    COUNT(DISTINCT n.n_nationkey) AS NationCount,
    AVG(cs.OrderCount) AS AvgOrdersPerCustomer,
    SUM(ss.TotalCost) AS TotalSupplierCost,
    SUM(ls.Revenue) AS TotalRevenue
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    CustomerOrderStats cs ON cs.c_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = n.n_nationkey
    )
JOIN
    SupplierStats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_container IN ('SM BOX', 'MED BAG')
    )
JOIN
    LineItemSummary ls ON ls.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        WHERE c.c_nationkey = n.n_nationkey
    )
GROUP BY
    r.r_name
ORDER BY
    Region;
