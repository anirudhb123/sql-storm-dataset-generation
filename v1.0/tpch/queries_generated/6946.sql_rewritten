WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM
        region r
    JOIN
        RankedSuppliers rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.s_nationkey)
    WHERE
        rs.rank <= 5
),
OrderStatistics AS (
    SELECT
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01'
    GROUP BY
        o.o_custkey
)
SELECT
    ts.r_name AS region_name,
    ts.s_name AS supplier_name,
    os.total_sales,
    os.order_count
FROM
    TopSuppliers ts
JOIN
    OrderStatistics os ON ts.s_suppkey = os.o_custkey
ORDER BY
    ts.r_name, os.total_sales DESC;