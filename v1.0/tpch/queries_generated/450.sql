WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM SupplierStats s
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM CustomerOrders c
)
SELECT 
    cs.c_name AS Customer_Name,
    ss.s_name AS Supplier_Name,
    COALESCE(cs.total_orders, 0) AS Total_Orders,
    COALESCE(cs.total_spent, 0) AS Total_Spent,
    COALESCE(ss.unique_parts_supplied, 0) AS Unique_Parts_Supplied,
    COALESCE(ss.total_available_qty, 0) AS Total_Available_Qty,
    COALESCE(ss.total_supply_cost, 0) AS Total_Supply_Cost
FROM RankedSuppliers ss
FULL OUTER JOIN RankedCustomers cs ON ss.supplier_rank = cs.customer_rank
WHERE (ss.total_supply_cost IS NOT NULL OR cs.total_spent IS NOT NULL)
ORDER BY cs.c_name ASC NULLS FIRST, ss.s_name ASC NULLS FIRST;
