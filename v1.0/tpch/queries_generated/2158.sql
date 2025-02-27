WITH CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrderStats c
    WHERE 
        total_orders > 5
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        RANK() OVER (ORDER BY total_available DESC) AS part_rank
    FROM 
        PartSupplierInfo p
)
SELECT 
    tc.c_name AS Customer,
    tp.p_name AS Top_Part,
    tp.total_available AS Available_Quantity,
    tp.total_supply_cost AS Total_Cost_to_Supply,
    cs.total_spent AS Total_Spent_by_Customer
FROM 
    TopCustomers tc
LEFT JOIN 
    TopParts tp ON tc.rank = tp.part_rank
LEFT JOIN 
    CustomerOrderStats cs ON tc.custkey = cs.c_custkey
WHERE 
    tp.part_rank <= 10
AND 
    (tp.total_supply_cost IS NOT NULL OR tp.total_available > 0)
ORDER BY 
    tc.total_orders DESC, cs.average_order_value DESC;
