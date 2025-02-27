WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderstatus IN ('O', 'F')
),
SupplierSummary AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
CustomerDetails AS (
    SELECT
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, n.n_name
)
SELECT
    c.c_name,
    c.nation_name,
    COALESCE(s.total_available_quantity, 0) AS available_quantity,
    COALESCE(s.avg_supply_cost, 0) AS average_supply_cost,
    COUNT(DISTINCT ro.o_orderkey) AS number_of_orders,
    SUM(ro.o_totalprice) AS total_order_value
FROM
    CustomerDetails c
LEFT JOIN
    RankedOrders ro ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey)
LEFT JOIN
    SupplierSummary s ON s.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT ro.o_orderkey FROM RankedOrders ro WHERE ro.order_rank <= 5))
WHERE
    c.total_spent > (SELECT AVG(total_spent) FROM CustomerDetails) 
    AND c.nation_name IS NOT NULL
GROUP BY
    c.c_name, c.nation_name, s.total_available_quantity, s.avg_supply_cost
ORDER BY
    total_order_value DESC, available_quantity DESC;
