WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_amount,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '2021-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
NationRegion AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM
        nation n
    LEFT JOIN
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT
    ns.nation_name,
    nr.region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(od.net_amount) AS average_order_value,
    SUM(ss.total_supply_cost) AS total_supplier_cost
FROM
    NationRegion nr
JOIN
    customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = nr.nation_name)
LEFT JOIN
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN
    OrderDetails od ON od.o_orderkey = o.o_orderkey
LEFT JOIN
    SupplierSummary ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_size > 10
    )
WHERE
    c.c_acctbal IS NOT NULL
    AND c.c_acctbal > 1000.00
GROUP BY
    ns.nation_name, nr.region_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    total_orders DESC, average_order_value DESC;
