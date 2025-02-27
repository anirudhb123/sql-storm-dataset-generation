WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY
        o.o_orderkey,
        c.c_name,
        c.c_nationkey
), 
SupplierStats AS (
    SELECT
        ps.ps_partkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey,
        s.s_name
)
SELECT
    r.r_name AS region,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY total_sales DESC) AS region_order,
    o.c_name AS customer_name,
    o.total_sales,
    COALESCE(ss.supplier_count, 0) AS supplier_count,
    COALESCE(ss.total_supply_cost, 0.00) AS total_supply_cost
FROM
    RankedOrders o
LEFT JOIN
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = o.c_name)
JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    SupplierStats ss ON ss.ps_partkey = (SELECT lineitem.l_partkey FROM lineitem WHERE lineitem.l_orderkey = o.o_orderkey LIMIT 1)
WHERE
    o.sales_rank <= 5
ORDER BY
    r.r_name,
    o.total_sales DESC;
