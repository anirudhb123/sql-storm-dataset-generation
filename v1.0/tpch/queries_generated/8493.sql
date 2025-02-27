WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity
    FROM
        lineitem l
    WHERE
        l.l_shipdate > '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY
        l.l_partkey
)
SELECT 
    ns.n_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(ss.total_supply_cost) AS total_supply_cost,
    SUM(ls.total_sales) AS total_sales,
    AVG(ls.avg_quantity) AS avg_quantity_per_lineitem
FROM
    nation ns
LEFT JOIN
    SupplierSummary ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN
    CustomerOrders cs ON cs.c_nationkey = ns.n_nationkey
LEFT JOIN
    LineItemStats ls ON ls.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = ns.n_nationkey)
GROUP BY
    ns.n_name
ORDER BY
    total_sales DESC, customer_count ASC;
