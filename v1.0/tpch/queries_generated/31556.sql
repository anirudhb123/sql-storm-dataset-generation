WITH RECURSIVE SalesCTE AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    UNION ALL
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) + total_sales AS total_sales,
        o.o_orderdate
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        SalesCTE s ON o.o_orderkey = s.o_orderkey
    WHERE
        o.o_orderdate < s.o_orderdate
),
CustomerFeedback AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS average_order_value
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
SupplierSales AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey
)
SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(s.total_cost) AS average_supplier_cost,
    SUM(CASE WHEN s.order_count > 0 THEN 1 ELSE 0 END) AS active_suppliers,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS region_rank
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN
    SupplierSales s ON s.order_count > 0
WHERE
    o.o_orderdate >= '2022-01-01' OR o.o_orderdate IS NULL
GROUP BY
    r.r_name, n.n_name, c.c_name
ORDER BY
    region_rank, total_orders DESC;
