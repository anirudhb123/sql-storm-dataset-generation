WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
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
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent,
        co.last_order_date
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > (
            SELECT AVG(total_spent) * 1.5 
            FROM CustomerOrders
        )
),
SupplierRanked AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY total_avail_qty DESC, avg_supply_cost ASC) AS rank
    FROM 
        SupplierStats s
)
SELECT 
    cus.c_name AS customer_name,
    sup.s_name AS supplier_name,
    sup.total_avail_qty,
    sup.avg_supply_cost,
    CONCAT('High Value Customer since ', TO_CHAR(cus.last_order_date, 'YYYY-MM-DD')) AS customer_status
FROM 
    HighValueCustomers cus
INNER JOIN 
    SupplierRanked sup ON cus.order_count > 5
LEFT JOIN 
    lineitem li ON li.l_suppkey = sup.s_suppkey
WHERE 
    li.l_returnflag IS NULL
    AND li.l_linestatus = 'O'
ORDER BY 
    cus.total_spent DESC, sup.rank;
