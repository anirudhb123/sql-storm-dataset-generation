WITH PartStats AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        MAX(ps.ps_supplycost) AS max_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    ps.p_partkey,
    ps.p_name,
    ps.p_brand,
    ps.p_type,
    ps.supplier_count,
    ps.max_supply_cost,
    ps.supplier_names,
    co.total_orders,
    co.total_spent,
    CASE
        WHEN co.total_spent > 10000 THEN 'High Value Customer'
        WHEN co.total_orders > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS customer_type
FROM
    PartStats ps
LEFT JOIN
    CustomerOrders co ON ps.p_partkey = (SELECT MAX(l.l_partkey) FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey))
ORDER BY
    ps.supplier_count DESC, co.total_spent DESC;
