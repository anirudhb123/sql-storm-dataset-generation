WITH RECURSIVE SalesTrend AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        1 AS level
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
    HAVING
        total_sales > 1000
    UNION ALL
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        level + 1
    FROM
        SalesTrend st
    JOIN
        orders o ON st.o_orderdate < o.o_orderdate
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        level < 5
    GROUP BY
        o.o_orderkey, o.o_orderdate
    HAVING
        total_sales > 1000
),
SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        total_cost > 5000
),
CustomerRanked AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM
        region r
    INNER JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_name, n.n_name
    HAVING
        COUNT(s.s_suppkey) > 0
)
SELECT
    c.c_name,
    c.total_spent,
    r.region_name,
    n.nation_name,
    ss.total_cost
FROM
    CustomerRanked c
JOIN
    NationRegion n ON c.c_custkey = (SELECT c_nationkey FROM customer WHERE c_name = c.c_name)
LEFT JOIN
    SupplierSummary ss ON ss.s_suppkey = (SELECT MIN(s_suppkey) FROM supplier WHERE s_name LIKE '%Corp%')
ORDER BY
    c.rank, total_spent DESC
LIMIT 10;
