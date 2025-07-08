WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_supply_cost, 
        ss.part_count
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    hs.s_name AS Supplier_Name,
    hc.c_name AS Customer_Name,
    hc.total_spent AS Total_Spent,
    hs.part_count AS Parts_Supplied,
    hs.total_supply_cost AS Total_Supply_Cost,
    ns.n_name AS Nation_Name,
    r.r_name AS Region_Name
FROM 
    HighValueSuppliers hs
JOIN 
    nation ns ON hs.s_suppkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = hs.s_suppkey)
JOIN 
    TopCustomers hc ON hc.total_spent > 10000
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
WHERE 
    hc.total_spent >= 1000
ORDER BY 
    hs.total_supply_cost DESC, hc.total_spent DESC;
