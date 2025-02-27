WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY AVG(ps.ps_supplycost) ASC) AS part_rank
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
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
),
FilteredCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(co.total_orders, 0) AS total_orders,
        COALESCE(co.total_spent, 0) AS total_spent,
        CASE 
            WHEN COALESCE(co.total_spent, 0) > 10000 THEN 'High Value'
            WHEN COALESCE(co.total_spent, 0) BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM
        customer c
    LEFT JOIN
        CustomerOrders co ON c.c_custkey = co.c_custkey
),
ProductSupply AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_supply_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT
    rpc.p_partkey,
    rpc.p_name,
    rpc.p_brand,
    rpc.total_avail_qty,
    rpc.avg_supply_cost,
    fc.c_custkey,
    fc.c_name,
    fc.total_orders,
    fc.total_spent,
    fc.customer_value,
    ps.total_supply_qty
FROM
    RankedParts rpc
JOIN
    ProductSupply ps ON rpc.p_partkey = ps.ps_partkey
FULL OUTER JOIN
    FilteredCustomers fc ON fc.total_orders > 0
WHERE
    fc.total_spent > (SELECT AVG(total_spent) FROM FilteredCustomers WHERE total_orders > 0)
    OR rpc.part_rank <= 3
ORDER BY
    fc.total_spent DESC, rpc.avg_supply_cost ASC;
