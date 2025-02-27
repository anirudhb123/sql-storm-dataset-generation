WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.part_count,
        ss.total_value
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_value > (SELECT AVG(total_value) FROM SupplierStats)
),
HighSpendingCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.order_count
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    hs.s_name AS supplier_name,
    hs.part_count AS number_of_parts,
    hc.c_name AS customer_name,
    hc.total_spent AS customer_spending,
    hc.order_count AS customer_orders
FROM 
    HighValueSuppliers hs
JOIN 
    HighSpendingCustomers hc ON hs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey
        WHERE li.l_orderkey IN (
            SELECT o.o_orderkey
            FROM orders o
            WHERE o.o_custkey = hc.c_custkey
        )
    )
ORDER BY 
    hs.total_value DESC, hc.total_spent DESC;
