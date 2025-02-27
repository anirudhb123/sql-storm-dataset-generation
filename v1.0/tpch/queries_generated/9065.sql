WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'F'
), TopOrders AS (
    SELECT
        ro.* 
    FROM
        RankedOrders ro
    WHERE
        ro.order_rank <= 5
), OrderDetails AS (
    SELECT
        to.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM
        TopOrders to
    JOIN
        lineitem l ON to.o_orderkey = l.l_orderkey
    GROUP BY
        to.o_orderkey
), SupplierStats AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        MIN(ps.ps_supplycost) AS minimum_supply_cost,
        MAX(ps.ps_supplycost) AS maximum_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
)
SELECT
    o.o_orderkey,
    o.o_orderdate,
    o.total_revenue,
    o.total_quantity,
    s.total_available_quantity,
    s.minimum_supply_cost,
    s.maximum_supply_cost,
    c.c_name,
    c.c_acctbal
FROM
    OrderDetails o
JOIN
    TopOrders to ON o.o_orderkey = to.o_orderkey
JOIN
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey))
JOIN
    customer c ON to.o_custkey = c.c_custkey
ORDER BY
    o.total_revenue DESC, to.o_orderdate ASC;
