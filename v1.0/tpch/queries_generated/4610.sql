WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
PartRegion AS (
    SELECT
        p.p_partkey,
        p.p_name,
        r.r_name AS region_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        part p
    LEFT JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY
        p.p_partkey, p.p_name, r.r_name
)
SELECT
    ps.s_name AS supplier_name,
    ps.total_supply_cost,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    pr.region_name,
    pr.avg_supply_cost
FROM
    SupplierStats ps
FULL OUTER JOIN 
    CustomerOrders co ON ps.part_count > co.order_count
LEFT JOIN 
    PartRegion pr ON ps.part_count < pr.avg_supply_cost
WHERE
    ps.total_supply_cost IS NOT NULL OR co.total_spent IS NOT NULL
ORDER BY
    ps.total_supply_cost DESC NULLS LAST, 
    co.total_spent DESC NULLS LAST;
